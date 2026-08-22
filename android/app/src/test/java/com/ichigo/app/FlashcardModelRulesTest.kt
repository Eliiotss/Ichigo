package com.ichigo.app

import com.ichigo.app.data.flashcard.FlashcardAnalyticsSummary
import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardDeckCard
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardMode
import com.ichigo.app.data.flashcard.FlashcardProgress
import com.ichigo.app.data.flashcard.flashcardLevelKey
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Locks the small pure rules behind stats, mastery, due-ness and enums. */
class FlashcardModelRulesTest {

    private val now = 1_700_000_000_000L

    private fun progress(state: FlashcardCardState, dueDate: Long, scheduledDays: Int) =
        FlashcardProgress(
            id = "c", level = "N5", front = "f", back = "b", state = state, dueDate = dueDate,
            stability = 1.0, difficulty = 5.0, reps = 1, lapses = 0, lastReview = null,
            scheduledDays = scheduledDays, learningStepIndex = 0,
        )

    @Test
    fun isDue_trueWhenDueDatePassed_falseWhenFuture() {
        assertTrue(progress(FlashcardCardState.REVIEW, now - 1, 1).isDue(now))
        assertTrue(progress(FlashcardCardState.REVIEW, now, 1).isDue(now))
        assertFalse(progress(FlashcardCardState.REVIEW, now + 1, 1).isDue(now))
    }

    @Test
    fun isMastered_requiresReviewStateAndTwentyOneDayInterval() {
        assertTrue(progress(FlashcardCardState.REVIEW, now, scheduledDays = 21).isMastered)
        assertTrue(progress(FlashcardCardState.REVIEW, now, scheduledDays = 40).isMastered)
        assertFalse(progress(FlashcardCardState.REVIEW, now, scheduledDays = 20).isMastered)
        // Same 21-day interval but not yet graduated to REVIEW → not mastered.
        assertFalse(progress(FlashcardCardState.LEARNING, now, scheduledDays = 21).isMastered)
    }

    @Test
    fun analyticsAccuracy_countsHardGoodEasy_excludesAgain() {
        val s = FlashcardAnalyticsSummary(
            totalReviews = 10, againCount = 2, hardCount = 3, goodCount = 4, easyCount = 1,
        )
        assertEquals(0.8, s.accuracy, 1e-9) // (3+4+1)/10
    }

    @Test
    fun analyticsAccuracy_zeroReviews_isZeroNotNaN() {
        val s = FlashcardAnalyticsSummary()
        assertEquals(0.0, s.accuracy, 1e-9)
        assertFalse(s.accuracy.isNaN())
    }

    @Test
    fun gradeRoundTrip_andUnknownFallsBackToGood() {
        for (g in FlashcardGrade.allCases) {
            assertEquals(g, FlashcardGrade.from(g.value))
        }
        assertEquals(FlashcardGrade.AGAIN, FlashcardGrade.from(1))
        assertEquals(FlashcardGrade.EASY, FlashcardGrade.from(4))
        assertEquals(FlashcardGrade.GOOD, FlashcardGrade.from(99)) // unknown → GOOD
    }

    @Test
    fun cardStateRoundTrip_andUnknownFallsBackToNew() {
        assertEquals(FlashcardCardState.REVIEW, FlashcardCardState.from("review"))
        assertEquals(FlashcardCardState.RELEARNING, FlashcardCardState.from("relearning"))
        assertEquals(FlashcardCardState.NEW, FlashcardCardState.from("garbage"))
    }

    @Test
    fun levelKey_combinesModeRawAndLevelId() {
        assertEquals("vocabulary_N2", flashcardLevelKey(FlashcardMode.VOCABULARY, "N2"))
        assertEquals("grammar_N3", flashcardLevelKey(FlashcardMode.GRAMMAR, "N3"))
    }

    @Test
    fun newProgress_startsUnseenWithNeutralFsrs() {
        val card = FlashcardDeckCard(
            id = "v1", mode = FlashcardMode.VOCABULARY, front = "日", revealedTitle = "ひ",
            revealedBody = "hari", revealedTag = "n",
        )
        val p = FlashcardProgress.newProgress(card, "vocabulary_N5", now)
        assertEquals(FlashcardCardState.NEW, p.state)
        assertEquals(0, p.reps)
        assertEquals(0, p.lapses)
        assertEquals(null, p.lastReview)
        assertEquals(5.0, p.difficulty, 1e-9)
        assertFalse(p.isMastered)
    }
}
