package com.ichigo.app

import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardProgress
import com.ichigo.app.data.flashcard.FlashcardReviewEngine
import com.ichigo.app.data.flashcard.FlashcardSettings
import com.ichigo.app.data.flashcard.FlashcardTime
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Locks the "cara A" scheduling: learning steps [1, 10] min, Good graduates to 1
 * day, Easy graduates straight to easyIntervalDays (tuned to 3). Pure JVM.
 */
class FlashcardReviewEngineTest {

    private val engine = FlashcardReviewEngine()
    private val settings = FlashcardSettings()
    private val now = 1_700_000_000_000L

    private fun newCard() = FlashcardProgress(
        id = "k1", level = "N5", front = "日", back = "hari",
        state = FlashcardCardState.NEW, dueDate = 0, stability = 0.0, difficulty = 0.0,
        reps = 0, lapses = 0, lastReview = null, scheduledDays = 0, learningStepIndex = 0,
    )

    @Test
    fun newCard_easy_graduatesToThreeDays() {
        val (p, _) = engine.review(newCard(), FlashcardGrade.EASY, settings, now)
        assertEquals(FlashcardCardState.REVIEW, p.state)
        assertEquals(3, p.scheduledDays) // easyIntervalDays tuned to 3
    }

    @Test
    fun newCard_again_entersLearningAtOneMinute() {
        val (p, _) = engine.review(newCard(), FlashcardGrade.AGAIN, settings, now)
        assertEquals(FlashcardCardState.LEARNING, p.state)
        assertEquals(0, p.learningStepIndex)
        assertEquals(FlashcardTime.addMinutes(now, 1.0), p.dueDate)
    }

    @Test
    fun learning_good_walksStepsThenGraduatesToOneDay() {
        val learning = newCard().apply { state = FlashcardCardState.LEARNING; learningStepIndex = 0 }
        val (p1, _) = engine.review(learning, FlashcardGrade.GOOD, settings, now)
        assertEquals(FlashcardCardState.LEARNING, p1.state)
        assertEquals(1, p1.learningStepIndex)
        assertEquals(FlashcardTime.addMinutes(now, 10.0), p1.dueDate)

        val (p2, _) = engine.review(p1, FlashcardGrade.GOOD, settings, now)
        assertEquals(FlashcardCardState.REVIEW, p2.state)
        assertEquals(1, p2.scheduledDays) // graduatingIntervalDays
    }

    @Test
    fun review_incrementsRepsAndStampsLastReview() {
        val (p, _) = engine.review(newCard(), FlashcardGrade.GOOD, settings, now)
        assertEquals(1, p.reps)
        assertEquals(now, p.lastReview)
    }
}
