package com.ichigo.app.data.flashcard

import java.util.UUID

/**
 * Direct port of `FlashcardReviewEngine`.
 *
 * The Anki-style "cara A" graduation is preserved exactly: new/learning cards
 * walk the learning steps [1, 10] minutes (Easy graduates immediately), the first
 * graduation uses a fixed interval (Good → graduatingIntervalDays, Easy →
 * easyIntervalDays), and every later review of a graduated card is scheduled by
 * full FSRS-6 (`graduateWithStability`).
 */
class FlashcardReviewEngine {

    fun review(
        card: FlashcardProgress,
        grade: FlashcardGrade,
        settings: FlashcardSettings,
        now: Long = System.currentTimeMillis(),
    ): Pair<FlashcardProgress, FlashcardReviewLog> {
        val updated = card.copy()
        val w = settings.fsrsWeights
        val elapsedDays = FlashcardTime.elapsedDays(card.lastReview, now).toDouble()

        updated.reps += 1
        updated.lastReview = now

        when (card.state) {
            // New card → learning steps (unless Easy graduates immediately).
            FlashcardCardState.NEW -> {
                updated.stability = FSRSMath.initialStability(grade, w)
                updated.difficulty = FSRSMath.initialDifficulty(grade, w)
                if (grade == FlashcardGrade.EASY) {
                    graduate(updated, settings.easyIntervalDays, settings, now)
                } else {
                    updated.state = FlashcardCardState.LEARNING
                    advanceStep(updated, currentIndex = -1, steps = settings.learningStepsMinutes, grade = grade, settings = settings, now = now)
                }
            }

            // Learning card — step progression continues.
            FlashcardCardState.LEARNING -> {
                updated.stability = FSRSMath.initialStability(grade, w)
                updated.difficulty = FSRSMath.initialDifficulty(grade, w)
                if (grade == FlashcardGrade.EASY) {
                    graduate(updated, settings.easyIntervalDays, settings, now)
                } else {
                    advanceStep(updated, currentIndex = card.learningStepIndex, steps = settings.learningStepsMinutes, grade = grade, settings = settings, now = now)
                }
            }

            // Review card — full FSRS applies.
            FlashcardCardState.REVIEW -> {
                val r = FSRSMath.retrievability(elapsedDays, card.stability, w)
                if (grade == FlashcardGrade.AGAIN) {
                    updated.lapses += 1
                    updated.stability = FSRSMath.nextStabilityOnForget(card.stability, card.difficulty, r, w)
                    updated.difficulty = FSRSMath.nextDifficulty(card.difficulty, grade, w)
                    updated.state = FlashcardCardState.RELEARNING
                    advanceStep(updated, currentIndex = -1, steps = settings.relearningStepsMinutes, grade = grade, settings = settings, now = now)
                } else {
                    updated.stability = FSRSMath.nextStabilityOnRecall(card.stability, card.difficulty, r, grade, w)
                    updated.difficulty = FSRSMath.nextDifficulty(card.difficulty, grade, w)
                    graduateWithStability(updated, settings, now)
                }
            }

            // Relearning card (red again after a lapse from review).
            FlashcardCardState.RELEARNING -> {
                if (grade == FlashcardGrade.EASY) {
                    graduate(updated, settings.easyIntervalDays, settings, now)
                } else {
                    if (grade == FlashcardGrade.AGAIN) updated.lapses += 1
                    advanceStep(updated, currentIndex = card.learningStepIndex, steps = settings.relearningStepsMinutes, grade = grade, settings = settings, now = now)
                }
            }
        }

        if (updated.lapses >= settings.leechThreshold) {
            updated.difficulty = 10.0
        }

        val log = FlashcardReviewLog(
            id = UUID.randomUUID().toString(),
            cardId = updated.id,
            levelId = updated.level,
            grade = grade,
            reviewedAt = now,
            nextDueDate = updated.dueDate,
            state = updated.state,
        )
        return updated to log
    }

    // Step progression exactly like Anki. currentIndex == -1 means "first entry".
    private fun advanceStep(
        updated: FlashcardProgress,
        currentIndex: Int,
        steps: List<Double>,
        grade: FlashcardGrade,
        settings: FlashcardSettings,
        now: Long,
    ) {
        when (grade) {
            FlashcardGrade.AGAIN -> {
                updated.learningStepIndex = 0
                updated.dueDate = FlashcardTime.addMinutes(now, steps.getOrNull(0) ?: 1.0)
                updated.scheduledDays = 0
            }
            FlashcardGrade.HARD -> {
                val idx = maxOf(currentIndex, 0)
                updated.learningStepIndex = idx
                updated.dueDate = FlashcardTime.addMinutes(now, steps.getOrNull(idx) ?: 1.0)
                updated.scheduledDays = 0
            }
            FlashcardGrade.GOOD -> {
                val nextIdx = currentIndex + 1
                if (nextIdx >= steps.size) {
                    graduate(updated, settings.graduatingIntervalDays, settings, now)
                } else {
                    updated.learningStepIndex = nextIdx
                    updated.dueDate = FlashcardTime.addMinutes(now, steps[nextIdx])
                    updated.scheduledDays = 0
                }
            }
            FlashcardGrade.EASY -> {
                graduate(updated, settings.easyIntervalDays, settings, now)
            }
        }
    }

    // First graduation from learning/relearning ("cara A"): fixed interval.
    private fun graduate(updated: FlashcardProgress, days: Int, settings: FlashcardSettings, now: Long) {
        val clamped = minOf(maxOf(days, 1), settings.maximumIntervalDays)
        updated.state = FlashcardCardState.REVIEW
        updated.learningStepIndex = 0
        updated.scheduledDays = clamped
        updated.dueDate = FlashcardTime.addDays(now, clamped)
    }

    // Every subsequent review of a graduated card: interval from FSRS-6 stability.
    private fun graduateWithStability(updated: FlashcardProgress, settings: FlashcardSettings, now: Long) {
        val days = FSRSMath.nextInterval(updated.stability, settings.desiredRetention, settings.maximumIntervalDays, settings.fsrsWeights)
        updated.state = FlashcardCardState.REVIEW
        updated.learningStepIndex = 0
        updated.scheduledDays = days
        updated.dueDate = FlashcardTime.addDays(now, days)
    }
}
