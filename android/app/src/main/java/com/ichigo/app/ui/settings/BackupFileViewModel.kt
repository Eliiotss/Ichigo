package com.ichigo.app.ui.settings

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.backup.BackupMerge
import com.ichigo.app.data.backup.BackupPayload
import com.ichigo.app.data.backup.BackupRepository
import com.ichigo.app.data.local.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

/**
 * File-based backup that needs **no Google setup at all**: export the local
 * progress to a `.json` file via the system file picker (which the user can then
 * upload to their own Google Drive, send to another phone, etc.) and restore it
 * later. Restore reuses [BackupMerge] so nothing is lost (newest-review-wins),
 * exactly like the Drive sync path.
 */
@HiltViewModel
class BackupFileViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val backup: BackupRepository,
    private val prefs: AppPreferences,
) : ViewModel() {

    data class UiState(val busy: Boolean = false, val message: String? = null, val isError: Boolean = false)

    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    /** Default file name suggested in the "save" dialog. */
    val suggestedFileName: String
        get() = "ichigo-backup-${SimpleDateFormat("yyyyMMdd-HHmm", Locale.US).format(Date())}.json"

    /** Serialize the current progress and write it to the picked file. */
    fun exportTo(uri: Uri) = viewModelScope.launch {
        _state.value = UiState(busy = true)
        runCatching {
            withContext(Dispatchers.IO) {
                val payload = backup.export(prefs.deviceId())
                val text = json.encodeToString(BackupPayload.serializer(), payload)
                context.contentResolver.openOutputStream(uri)?.use { it.write(text.toByteArray()) }
                    ?: error("Tidak bisa menulis berkas")
            }
        }.onSuccess {
            _state.value = UiState(message = "Cadangan berhasil disimpan.")
        }.onFailure {
            _state.value = UiState(message = "Gagal menyimpan: ${it.message}", isError = true)
        }
    }

    /** Read a backup file, merge it with the current progress, and apply. */
    fun importFrom(uri: Uri) = viewModelScope.launch {
        _state.value = UiState(busy = true)
        runCatching {
            withContext(Dispatchers.IO) {
                val text = context.contentResolver.openInputStream(uri)?.use { it.readBytes().decodeToString() }
                    ?: error("Tidak bisa membaca berkas")
                val remote = json.decodeFromString(BackupPayload.serializer(), text)
                val local = backup.export(prefs.deviceId())
                backup.apply(BackupMerge.merge(local, remote))
            }
        }.onSuccess {
            _state.value = UiState(message = "Cadangan dipulihkan & digabung.")
        }.onFailure {
            _state.value = UiState(message = "Gagal memulihkan — berkas cadangan tidak valid?", isError = true)
        }
    }
}
