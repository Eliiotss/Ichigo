package com.ichigo.app

import com.ichigo.app.data.backup.BackupKana
import com.ichigo.app.data.backup.BackupMerge
import com.ichigo.app.data.backup.BackupNewToday
import com.ichigo.app.data.backup.BackupPayload
import com.ichigo.app.data.backup.BackupProgress
import com.ichigo.app.data.backup.BackupQuizResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Locks the merge rules so backup/restore never loses progress. Pure JVM. */
class BackupMergeTest {

    private fun prog(id: String, lastReview: Long?, reps: Int) = BackupProgress(
        id = id, level = "N5", front = "f", back = "b", state = "review",
        dueDate = 0, stability = 1.0, difficulty = 5.0, reps = reps, lapses = 0,
        lastReview = lastReview, scheduledDays = 1, learningStepIndex = 0,
    )

    @Test
    fun perCard_newerLastReviewWins() {
        val a = BackupPayload(createdAt = 100, progress = listOf(prog("c1", 500, reps = 5)))
        val b = BackupPayload(createdAt = 200, progress = listOf(prog("c1", 900, reps = 9)))
        val m = BackupMerge.merge(a, b)
        assertEquals(1, m.progress.size)
        assertEquals(9, m.progress.first().reps)
    }

    @Test
    fun nullLastReview_losesToRealReview() {
        val a = BackupPayload(progress = listOf(prog("c1", null, reps = 0)))
        val b = BackupPayload(progress = listOf(prog("c1", 100, reps = 3)))
        val m = BackupMerge.merge(a, b)
        assertEquals(3, m.progress.first().reps)
    }

    @Test
    fun streakTakesHigher_preferencesFromNewerSnapshot() {
        val a = BackupPayload(createdAt = 100, streak = 3, userName = "A", dailyTarget = 20)
        val b = BackupPayload(createdAt = 200, streak = 7, userName = "B", dailyTarget = 30)
        val m = BackupMerge.merge(a, b)
        assertEquals(7, m.streak)
        assertEquals("B", m.userName)
        assertEquals(30, m.dailyTarget)
    }

    @Test
    fun newTodayUnion_andKanaMax() {
        val a = BackupPayload(
            newToday = listOf(BackupNewToday("N5", "2026-01-01", "c1")),
            kanaCounts = listOf(BackupKana("あ", "hira", 3)),
        )
        val b = BackupPayload(
            newToday = listOf(BackupNewToday("N5", "2026-01-01", "c1"), BackupNewToday("N5", "2026-01-01", "c2")),
            kanaCounts = listOf(BackupKana("あ", "hira", 5)),
        )
        val m = BackupMerge.merge(a, b)
        assertEquals(2, m.newToday.size)
        assertEquals(5, m.kanaCounts.first { it.kana == "あ" }.count)
    }

    @Test
    fun quizResult_newerLastAnsweredWins() {
        val a = BackupPayload(quizResults = listOf(BackupQuizResult("w1", score = 1, lastAnswered = 100)))
        val b = BackupPayload(quizResults = listOf(BackupQuizResult("w1", score = -1, lastAnswered = 200)))
        assertEquals(-1, BackupMerge.merge(a, b).quizResults.single().score)
        assertEquals(-1, BackupMerge.merge(b, a).quizResults.single().score)
    }

    @Test
    fun quizResult_droppedByReset() {
        val reset = 1_000L
        val local = BackupPayload(createdAt = 2, resetAt = reset) // reset device, quiz wiped
        val remote = BackupPayload(createdAt = 1, quizResults = listOf(BackupQuizResult("old", 3, lastAnswered = 500)))
        assertTrue(BackupMerge.merge(local, remote).quizResults.isEmpty())
    }
}
