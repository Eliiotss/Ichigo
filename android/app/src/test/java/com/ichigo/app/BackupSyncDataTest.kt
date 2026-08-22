package com.ichigo.app

import com.ichigo.app.data.backup.BackupKana
import com.ichigo.app.data.backup.BackupMerge
import com.ichigo.app.data.backup.BackupPayload
import com.ichigo.app.data.backup.BackupProgress
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Guards the Google Drive sync **data layer**: JSON round-trips, forward-compatible
 * decoding (version migration safety), corrupted-payload handling, and the
 * per-item merge that protects progress across devices. Pure JVM — no Android,
 * no network. Mirrors the same [Json] config the sync manager uses.
 */
class BackupSyncDataTest {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    private fun card(id: String, lastReview: Long?, reps: Int = 0, lapses: Int = 0) =
        BackupProgress(
            id = id, level = "N5", front = "日", back = "hari", state = "review",
            dueDate = 111L, stability = 4.2, difficulty = 5.5, reps = reps, lapses = lapses,
            lastReview = lastReview, scheduledDays = 3, learningStepIndex = 1,
        )

    // 2 + 3. Encode then decode reproduces every FSRS field exactly.
    @Test
    fun jsonRoundTrip_preservesAllFsrsFields() {
        val original = BackupPayload(
            schemaVersion = 1,
            createdAt = 1234L,
            deviceId = "dev-A",
            progress = listOf(card("c1", lastReview = 999L, reps = 7, lapses = 2)),
            streak = 5,
            kanaCounts = listOf(BackupKana("あ", "hira", 4)),
        )
        val encoded = json.encodeToString(BackupPayload.serializer(), original)
        val decoded = json.decodeFromString(BackupPayload.serializer(), encoded)
        assertEquals(original, decoded)
        val c = decoded.progress.single()
        assertEquals(4.2, c.stability, 0.0)
        assertEquals(5.5, c.difficulty, 0.0)
        assertEquals(7, c.reps)
        assertEquals(2, c.lapses)
        assertEquals(999L, c.lastReview)
        assertEquals(1, c.learningStepIndex)
    }

    // 6. Local-only cards survive a merge with a remote snapshot that lacks them.
    @Test
    fun localOnlyCard_isKept() {
        val local = BackupPayload(progress = listOf(card("local1", 100L)))
        val remote = BackupPayload(progress = listOf(card("remote1", 200L)))
        val merged = BackupMerge.merge(local, remote)
        val ids = merged.progress.map { it.id }.toSet()
        assertTrue("local-only kept", "local1" in ids)
        assertTrue("remote-only added", "remote1" in ids)
        assertEquals(2, merged.progress.size)
    }

    // 9 + 10. Whichever side reviewed the card more recently wins, either direction.
    @Test
    fun newerReviewWins_bothDirections() {
        val newerLocal = BackupMerge.merge(
            BackupPayload(createdAt = 1, progress = listOf(card("c", 900L, reps = 9))),
            BackupPayload(createdAt = 2, progress = listOf(card("c", 100L, reps = 1))),
        )
        assertEquals(9, newerLocal.progress.single().reps)

        val newerRemote = BackupMerge.merge(
            BackupPayload(createdAt = 2, progress = listOf(card("c", 100L, reps = 1))),
            BackupPayload(createdAt = 1, progress = listOf(card("c", 900L, reps = 9))),
        )
        assertEquals(9, newerRemote.progress.single().reps)
    }

    // 12. Merging against an empty backup never wipes existing progress.
    @Test
    fun emptyBackup_doesNotWipeProgress() {
        val local = BackupPayload(progress = listOf(card("c1", 10L), card("c2", 20L)), streak = 4)
        val merged = BackupMerge.merge(local, BackupPayload())
        assertEquals(2, merged.progress.size)
        assertEquals(4, merged.streak)
    }

    // 13. A corrupted/garbage payload fails to decode — the sync manager treats
    // this as "no usable remote" and keeps local data (runCatching → null).
    @Test
    fun corruptedJson_failsToDecode() {
        val decoded = runCatching {
            json.decodeFromString(BackupPayload.serializer(), "{ this is not valid json ]")
        }.getOrNull()
        assertNull(decoded)
    }

    // 14. Forward compatibility: a backup written by a newer version (extra fields,
    // higher schemaVersion) still decodes without crashing, and version is retained.
    @Test
    fun unknownFieldsAndFutureVersion_decodeSafely() {
        val futureJson = """
            {"schemaVersion":99,"createdAt":5,"deviceId":"x","progress":[],
             "streak":2,"kanaCounts":[],"aFieldFromTheFuture":{"nested":true},
             "anotherNewField":[1,2,3]}
        """.trimIndent()
        val decoded = runCatching {
            json.decodeFromString(BackupPayload.serializer(), futureJson)
        }.getOrNull()
        assertNotNull("future backup must not crash the decoder", decoded)
        assertEquals(99, decoded!!.schemaVersion)
        assertEquals(2, decoded.streak)
    }

    // schemaVersion after a merge keeps the higher of the two (no silent downgrade).
    @Test
    fun mergeKeepsHigherSchemaVersion() {
        val merged = BackupMerge.merge(
            BackupPayload(schemaVersion = 1),
            BackupPayload(schemaVersion = 2),
        )
        assertEquals(2, merged.schemaVersion)
    }
}
