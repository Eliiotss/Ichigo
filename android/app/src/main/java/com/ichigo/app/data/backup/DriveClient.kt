package com.ichigo.app.data.backup

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Minimal Google Drive v3 client for the app's private **appDataFolder** — only
 * files this app creates are visible, never the user's other Drive files (scope
 * `drive.appdata`). Mirrors the iOS `GoogleDriveClient`. Plain REST over OkHttp;
 * the OAuth bearer token is supplied by the sync manager per call.
 */
@Singleton
class DriveClient @Inject constructor() {

    private val http = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val jsonType = "application/json; charset=UTF-8".toMediaType()

    /**
     * A backup file on Drive. [version] is Drive's monotonically increasing
     * change counter for the file — it moves on **every** server-side change,
     * so comparing it before writing detects another device having uploaded in
     * the meantime. Drive v3 has no `If-Match` precondition on `files.update`,
     * so a read-verify-write check is the only concurrency control available.
     */
    data class DriveFile(val id: String, val version: String)

    /** Finds the backup file in appDataFolder, or null if it doesn't exist yet. */
    fun findBackupFile(token: String): DriveFile? {
        val url = "https://www.googleapis.com/drive/v3/files" +
            "?spaces=appDataFolder&fields=files(id,name,version)&q=" +
            // trashed = false: a backup the user deleted must not be resurrected
            // as the sync target (which would silently drop newer progress).
            java.net.URLEncoder.encode("name = '$BACKUP_NAME' and trashed = false", "UTF-8")
        val req = Request.Builder().url(url).header("Authorization", "Bearer $token").get().build()
        http.newCall(req).execute().use { resp ->
            val body = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw IOException("Drive list gagal (${resp.code}): $body")
            val files = JSONObject(body).optJSONArray("files") ?: return null
            if (files.length() == 0) return null
            val f = files.getJSONObject(0)
            return DriveFile(f.getString("id"), f.optString("version", ""))
        }
    }

    /** Current version counter of a file, used to detect a concurrent write. */
    fun fileVersion(token: String, fileId: String): String {
        val url = "https://www.googleapis.com/drive/v3/files/$fileId?fields=version"
        val req = Request.Builder().url(url).header("Authorization", "Bearer $token").get().build()
        http.newCall(req).execute().use { resp ->
            val body = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw IOException("Drive version gagal (${resp.code}): $body")
            return JSONObject(body).optString("version", "")
        }
    }

    /** Downloads the backup file content (raw JSON). */
    fun download(token: String, fileId: String): String {
        val url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media"
        val req = Request.Builder().url(url).header("Authorization", "Bearer $token").get().build()
        http.newCall(req).execute().use { resp ->
            val body = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw IOException("Drive download gagal (${resp.code}): $body")
            return body
        }
    }

    /** Creates the backup file in appDataFolder, returning its new id. */
    fun create(token: String, json: String): String {
        val metadata = JSONObject()
            .put("name", BACKUP_NAME)
            .put("parents", org.json.JSONArray().put("appDataFolder"))
            .toString()
        // MUST be the full "multipart/related" media type. A bare "related"
        // has no subtype, so OkHttp's toMediaType() throws IllegalArgumentException
        // and the very first sync (the only time this create path runs) always
        // failed with "Gagal sinkron: No subtype found for: \"related\"".
        val body = MultipartBody.Builder().setType("multipart/related".toMediaType())
            .addPart(metadata.toRequestBody(jsonType))
            .addPart(json.toRequestBody(jsonType))
            .build()
        val req = Request.Builder()
            .url("https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id")
            .header("Authorization", "Bearer $token")
            .post(body)
            .build()
        http.newCall(req).execute().use { resp ->
            val respBody = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw IOException("Drive create gagal (${resp.code}): $respBody")
            return JSONObject(respBody).getString("id")
        }
    }

    /** Overwrites an existing backup file's content. */
    fun update(token: String, fileId: String, json: String) {
        val req = Request.Builder()
            .url("https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media")
            .header("Authorization", "Bearer $token")
            .patch(json.toRequestBody(jsonType))
            .build()
        http.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) throw IOException("Drive update gagal (${resp.code}): ${resp.body?.string()}")
        }
    }

    companion object {
        private const val BACKUP_NAME = "ichigo-backup.json"
    }
}
