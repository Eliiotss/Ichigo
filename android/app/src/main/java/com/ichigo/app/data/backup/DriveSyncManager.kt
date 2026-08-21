package com.ichigo.app.data.backup

import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.UserRecoverableAuthException
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.auth.api.signin.GoogleSignInStatusCodes
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Scope
import com.ichigo.app.data.local.AppPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Orchestrates Google Drive two-way sync, the Android counterpart of the iOS
 * `DriveBackupManager`. Sign-in uses Google Sign-In (requesting the
 * `drive.appdata` scope); the OAuth token is fetched with `GoogleAuthUtil` and
 * used by [DriveClient]. A sync is pull → merge → apply → push, so studying on
 * one device shows up on the next, never losing progress.
 */
@Singleton
class DriveSyncManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val drive: DriveClient,
    private val backup: BackupRepository,
    private val prefs: AppPreferences,
) {
    data class DriveState(
        val signedIn: Boolean = false,
        val email: String? = null,
        val busy: Boolean = false,
        val lastSyncAt: Long? = null,
        val message: String? = null,
        val isError: Boolean = false,
    )

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    private val _state = MutableStateFlow(DriveState())
    val state: StateFlow<DriveState> = _state.asStateFlow()

    /** When non-null, the UI must launch this consent intent then retry the sync. */
    private val _recoveryIntent = MutableStateFlow<Intent?>(null)
    val recoveryIntent: StateFlow<Intent?> = _recoveryIntent.asStateFlow()

    private val driveScope = Scope(DRIVE_APPDATA)

    private val signInOptions: GoogleSignInOptions
        get() = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestScopes(driveScope)
            .build()

    fun signInIntent(): Intent = GoogleSignIn.getClient(context, signInOptions).signInIntent

    /** Refreshes the signed-in state from the last account (call on screen enter). */
    suspend fun refreshState() {
        val acc = GoogleSignIn.getLastSignedInAccount(context)
        _state.value = _state.value.copy(
            signedIn = acc != null && GoogleSignIn.hasPermissions(acc, driveScope),
            email = acc?.email,
            lastSyncAt = prefs.driveLastSyncOrNull(),
        )
    }

    suspend fun onSignInResult(data: Intent?) {
        try {
            val acc = GoogleSignIn.getSignedInAccountFromIntent(data).getResult(ApiException::class.java)
            prefs.setGoogleEmail(acc.email)
            _state.value = _state.value.copy(
                signedIn = GoogleSignIn.hasPermissions(acc, driveScope),
                email = acc.email,
                message = "Berhasil masuk.",
                isError = false,
            )
            syncNow()
        } catch (e: ApiException) {
            _state.value = _state.value.copy(message = signInErrorMessage(e.statusCode), isError = true)
        } catch (e: Exception) {
            _state.value = _state.value.copy(message = "Gagal masuk: ${e.message}", isError = true)
        }
    }

    /** Maps a Google Sign-In status code to a clear, actionable message (Indonesian). */
    private fun signInErrorMessage(code: Int): String = when (code) {
        CommonStatusCodes.DEVELOPER_ERROR -> // 10
            "Gagal masuk (kode 10): konfigurasi OAuth belum lengkap. Daftarkan SHA-1 " +
                "+ package \"com.ichigo.app\" pada OAuth Client ID (Android) di Google " +
                "Cloud Console, dan tambahkan akunmu sebagai Test user. Lihat docs/GoogleDriveSync.md."
        GoogleSignInStatusCodes.SIGN_IN_CANCELLED -> // 12501
            "Masuk dibatalkan."
        GoogleSignInStatusCodes.SIGN_IN_CURRENTLY_IN_PROGRESS -> // 12502
            "Proses masuk sedang berjalan, tunggu sebentar."
        CommonStatusCodes.NETWORK_ERROR -> // 7
            "Tidak ada koneksi internet."
        GoogleSignInStatusCodes.SIGN_IN_FAILED -> // 12500
            "Gagal masuk (kode 12500): pastikan Google Drive API aktif dan scope " +
                "drive.appdata sudah ditambahkan di OAuth consent screen."
        else ->
            "Gagal masuk (kode $code): ${GoogleSignInStatusCodes.getStatusCodeString(code)}."
    }

    fun signOut() {
        GoogleSignIn.getClient(context, signInOptions).signOut()
        _state.value = DriveState()
    }

    suspend fun clearGoogleEmail() = prefs.setGoogleEmail(null)

    fun consumeRecoveryIntent() { _recoveryIntent.value = null }

    suspend fun syncNow() {
        val acc = GoogleSignIn.getLastSignedInAccount(context)
        if (acc == null || !GoogleSignIn.hasPermissions(acc, driveScope)) {
            _state.value = _state.value.copy(message = "Belum masuk / izin Drive belum diberikan.", isError = true)
            return
        }
        _state.value = _state.value.copy(busy = true, message = null, isError = false)
        try {
            withContext(Dispatchers.IO) {
                val token = fetchToken(acc)
                // Read → merge → verify-nothing-changed → write. Drive v3 offers
                // no If-Match precondition on files.update, so the version counter
                // read back just before the upload is the only way to notice that
                // another device wrote while we were merging. Without it the last
                // writer silently overwrote the other device's newer progress.
                var attempt = 0
                while (true) {
                    val file = drive.findBackupFile(token)
                    val local = backup.export(prefs.deviceId())
                    val merged = if (file != null) {
                        val remoteJson = drive.download(token, file.id)
                        val remote = runCatching { json.decodeFromString(BackupPayload.serializer(), remoteJson) }.getOrNull()
                        if (remote != null) BackupMerge.merge(local, remote) else local
                    } else {
                        local
                    }
                    val out = json.encodeToString(BackupPayload.serializer(), merged)

                    if (file == null) {
                        drive.create(token, out)
                    } else {
                        val versionNow = runCatching { drive.fileVersion(token, file.id) }.getOrDefault(file.version)
                        if (versionNow != file.version && attempt < MAX_MERGE_RETRIES) {
                            attempt += 1
                            continue // someone else uploaded mid-merge — redo with their data
                        }
                        drive.update(token, file.id, out)
                    }
                    // Only touch local storage once the upload has succeeded, so a
                    // failed sync never leaves the device in a half-merged state.
                    backup.apply(merged)
                    break
                }
            }
            val now = System.currentTimeMillis()
            prefs.setDriveLastSync(now)
            _state.value = _state.value.copy(busy = false, lastSyncAt = now, message = "Sinkronisasi selesai.", isError = false)
        } catch (e: UserRecoverableAuthException) {
            _recoveryIntent.value = e.intent
            _state.value = _state.value.copy(busy = false, message = "Perlu izin Google Drive. Setujui lalu coba lagi.", isError = true)
        } catch (e: Exception) {
            _state.value = _state.value.copy(busy = false, message = "Gagal sinkron: ${e.message}", isError = true)
        }
    }

    /** Pull-merge on foreground / push after study, only when auto-sync is on. */
    suspend fun autoSyncIfEnabled() {
        if (!prefs.autoSyncNow()) return
        val acc = GoogleSignIn.getLastSignedInAccount(context) ?: return
        if (!GoogleSignIn.hasPermissions(acc, driveScope)) return
        syncNow()
    }

    private fun fetchToken(acc: GoogleSignInAccount): String {
        val account = acc.account ?: throw IllegalStateException("Akun Google tidak tersedia")
        return GoogleAuthUtil.getToken(context, account, "oauth2:$DRIVE_APPDATA")
    }

    companion object {
        private const val DRIVE_APPDATA = "https://www.googleapis.com/auth/drive.appdata"

        /** How many times to redo the merge when Drive changed underneath us. */
        private const val MAX_MERGE_RETRIES = 2
    }
}
