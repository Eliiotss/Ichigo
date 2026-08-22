package com.ichigo.app

import com.ichigo.app.data.backup.BackupAnalytics
import com.ichigo.app.data.backup.BackupKana
import com.ichigo.app.data.backup.BackupMerge
import com.ichigo.app.data.backup.BackupNewToday
import com.ichigo.app.data.backup.BackupPayload
import com.ichigo.app.data.backup.BackupProgress
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Locks the reset tombstone (`BackupPayload.resetAt`).
 *
 * Before it existed, "Reset progress" was silently undone by the next Drive
 * sync: the merge is a union and `apply` only upserts, so every deleted card
 * came straight back down from the cloud. These tests pin the new rule —
 * anything not studied since the newest reset is gone — and, just as important,
 * pin that a backup **without** a tombstone still behaves exactly as before.
 */
class BackupResetTombstoneTest {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    private val reset = 1_700_000_000_000L
    private val beforeReset = reset - 60_000L
    private val afterReset = reset + 60_000L

    private fun card(id: String, lastReview: Long?) = BackupProgress(
        id = id, level = "vocabulary_N5", front = "日", back = "hari", state = "review",
        dueDate = 0, stability = 4.0, difficulty = 5.0, reps = 3, lapses = 0,
        lastReview = lastReview, scheduledDays = 4, learningStepIndex = 0,
    )

    // -- Backward compatibility ----------------------------------------------

    @Test
    fun withoutTombstone_nothingIsDropped() {
        val a = BackupPayload(progress = listOf(card("old1", 1L), card("never", null)), streak = 4)
        val b = BackupPayload(progress = listOf(card("old2", 2L)))
        val merged = BackupMerge.merge(a, b)
        assertEquals(setOf("old1", "never", "old2"), merged.progress.map { it.id }.toSet())
        assertEquals(4, merged.streak)
        assertNull("no tombstone must stay absent", merged.resetAt)
    }

    @Test
    fun backupFromAnOlderVersion_decodesWithoutTombstone() {
        // Exactly what a pre-tombstone client writes: no "resetAt" key at all.
        val legacy = """{"schemaVersion":1,"createdAt":5,"deviceId":"old","progress":[],"streak":3}"""
        val decoded = json.decodeFromString(BackupPayload.serializer(), legacy)
        assertNull(decoded.resetAt)
        assertEquals(3, decoded.streak)
    }

    @Test
    fun tombstoneSurvivesAJsonRoundTrip() {
        val original = BackupPayload(resetAt = reset, progress = listOf(card("c", afterReset)))
        val decoded = json.decodeFromString(
            BackupPayload.serializer(),
            json.encodeToString(BackupPayload.serializer(), original),
        )
        assertEquals(reset, decoded.resetAt)
    }

    // -- The core rule --------------------------------------------------------

    @Test
    fun cardsNotStudiedSinceTheResetAreDropped() {
        val local = BackupPayload(createdAt = afterReset, resetAt = reset)      // just reset, empty
        val remote = BackupPayload(
            createdAt = beforeReset,
            progress = listOf(card("stale", beforeReset), card("neverSeen", null)),
        )
        val merged = BackupMerge.merge(local, remote)
        assertTrue("reset must not be undone by the cloud copy", merged.progress.isEmpty())
        assertEquals(reset, merged.resetAt)
    }

    @Test
    fun cardsStudiedAfterTheResetAreKept() {
        val local = BackupPayload(
            createdAt = afterReset,
            resetAt = reset,
            progress = listOf(card("fresh", afterReset)),
        )
        val remote = BackupPayload(createdAt = beforeReset, progress = listOf(card("stale", beforeReset)))
        val merged = BackupMerge.merge(local, remote)
        assertEquals(listOf("fresh"), merged.progress.map { it.id })
    }

    @Test
    fun aCardReviewedExactlyAtTheResetInstantIsKept() {
        val merged = BackupMerge.merge(
            BackupPayload(resetAt = reset),
            BackupPayload(progress = listOf(card("edge", reset))),
        )
        assertEquals(listOf("edge"), merged.progress.map { it.id })
    }

    @Test
    fun theRuleIsSymmetric_argumentOrderDoesNotMatter() {
        val withReset = BackupPayload(createdAt = afterReset, resetAt = reset)
        val stale = BackupPayload(createdAt = beforeReset, progress = listOf(card("stale", beforeReset)))
        assertEquals(
            BackupMerge.merge(withReset, stale).progress.map { it.id },
            BackupMerge.merge(stale, withReset).progress.map { it.id },
        )
    }

    @Test
    fun theNewestResetWins() {
        val older = BackupPayload(resetAt = reset, progress = listOf(card("mid", reset + 10)))
        val newer = BackupPayload(resetAt = reset + 100)
        val merged = BackupMerge.merge(older, newer)
        assertEquals(reset + 100, merged.resetAt)
        assertTrue("card studied before the newer reset must go", merged.progress.isEmpty())
    }

    // -- Everything that hangs off the progress -------------------------------

    @Test
    fun newTodayEntriesOfDroppedCardsAreRemoved() {
        val local = BackupPayload(
            createdAt = afterReset,
            resetAt = reset,
            progress = listOf(card("fresh", afterReset)),
            newToday = listOf(BackupNewToday("vocabulary_N5", "2026-08-21-Asia/Jakarta", "fresh")),
        )
        val remote = BackupPayload(
            createdAt = beforeReset,
            progress = listOf(card("stale", beforeReset)),
            newToday = listOf(BackupNewToday("vocabulary_N5", "2026-08-20-Asia/Jakarta", "stale")),
        )
        val merged = BackupMerge.merge(local, remote)
        assertEquals(listOf("fresh"), merged.newToday.map { it.cardId })
    }

    @Test
    fun staleStreakAndAnalyticsDoNotComeBack() {
        val local = BackupPayload(createdAt = afterReset, resetAt = reset, streak = 0)
        val remote = BackupPayload(
            createdAt = beforeReset,
            streak = 42,
            analytics = BackupAnalytics(totalReviews = 900, good = 900, lastReviewedAt = beforeReset),
        )
        val merged = BackupMerge.merge(local, remote)
        assertEquals(0, merged.streak)
        assertEquals(0, merged.analytics.totalReviews)
    }

    @Test
    fun analyticsFromADeviceThatStudiedAfterTheResetAreKept() {
        val resetter = BackupPayload(createdAt = afterReset, resetAt = reset, streak = 1)
        val stillStudying = BackupPayload(
            createdAt = afterReset,
            streak = 5,
            progress = listOf(card("fresh", afterReset)),
            analytics = BackupAnalytics(totalReviews = 12, good = 12, lastReviewedAt = afterReset),
        )
        val merged = BackupMerge.merge(resetter, stillStudying)
        assertEquals(12, merged.analytics.totalReviews)
        assertEquals(5, merged.streak)
    }

    @Test
    fun kanaProgressIsNotTouchedByAReset() {
        // resetAll() deliberately leaves the kana_count table alone, so the
        // tombstone must not wipe kana mastery either.
        val local = BackupPayload(createdAt = afterReset, resetAt = reset)
        val remote = BackupPayload(
            createdAt = beforeReset,
            kanaCounts = listOf(BackupKana("あ", "hira", 25)),
        )
        val merged = BackupMerge.merge(local, remote)
        assertEquals(25, merged.kanaCounts.single { it.kana == "あ" }.count)
    }

    @Test
    fun aResetDoesNotDiscardAnotherDevicesOngoingWork() {
        // Device B kept studying after the reset instant; its cards must survive
        // even though device A is the one carrying the tombstone.
        val deviceA = BackupPayload(createdAt = afterReset + 5, resetAt = reset)
        val deviceB = BackupPayload(
            createdAt = afterReset,
            progress = listOf(card("b1", afterReset), card("b2", afterReset + 1)),
        )
        val merged = BackupMerge.merge(deviceA, deviceB)
        assertEquals(setOf("b1", "b2"), merged.progress.map { it.id }.toSet())
        assertFalse(merged.progress.isEmpty())
    }
}
