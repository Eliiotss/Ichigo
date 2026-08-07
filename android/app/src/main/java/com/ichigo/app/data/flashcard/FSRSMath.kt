package com.ichigo.app.data.flashcard

import kotlin.math.exp
import kotlin.math.pow

/**
 * Direct port of `FSRSMath` — the official FSRS-6 formulas used by recent Anki.
 * Every formula, clamp and index matches the Swift source line for line, so a
 * card scheduled on Android lands on the same due date as on iOS.
 */
object FSRSMath {
    // FSRS-6: decay & factor are derived from w[20] (per-preset), not constants.
    private fun decay(w: List<Double>): Double {
        if (w.size <= 20) return -0.5 // fallback if the array is too short
        return -maxOf(w[20], 0.1)
    }

    private fun factor(w: List<Double>): Double {
        val d = decay(w)
        return 0.9.pow(1.0 / d) - 1
    }

    /** Retrievability: probability the card is still remembered after t days. */
    fun retrievability(elapsedDays: Double, stability: Double, w: List<Double>): Double {
        if (stability <= 0) return 0.0
        return (1 + factor(w) * elapsedDays / stability).pow(decay(w))
    }

    /** Initial stability when a new card is first graded. */
    fun initialStability(grade: FlashcardGrade, w: List<Double>): Double =
        maxOf(w[grade.value - 1], 0.1)

    /** Initial difficulty when a new card is first graded. */
    fun initialDifficulty(grade: FlashcardGrade, w: List<Double>): Double {
        val d = w[4] - (exp(w[5] * (grade.value - 1).toDouble()) - 1)
        return clamp(d, 1.0, 10.0)
    }

    /**
     * Difficulty update each review — FSRS-6 with linear damping `(10 - D)/9` and
     * mean reversion toward the Easy initial difficulty with weight w[7].
     */
    fun nextDifficulty(current: Double, grade: FlashcardGrade, w: List<Double>): Double {
        val deltaDifficulty = -w[6] * (grade.value.toDouble() - 3)
        val damped = current + deltaDifficulty * (10.0 - current) / 9.0
        val easyD0 = initialDifficulty(FlashcardGrade.EASY, w)
        val reverted = w[7] * easyD0 + (1 - w[7]) * damped
        return clamp(reverted, 1.0, 10.0)
    }

    /** Stability after a successful recall (Hard/Good/Easy). */
    fun nextStabilityOnRecall(
        stability: Double,
        difficulty: Double,
        retrievability: Double,
        grade: FlashcardGrade,
        w: List<Double>,
    ): Double {
        val hardPenalty = if (grade == FlashcardGrade.HARD) w[15] else 1.0
        val easyBonus = if (grade == FlashcardGrade.EASY) w[16] else 1.0
        val increase = exp(w[8]) * (11 - difficulty) * stability.pow(-w[9]) *
            (exp((1 - retrievability) * w[10]) - 1) * hardPenalty * easyBonus
        return maxOf(stability * (1 + increase), 0.1)
    }

    /** Stability after a lapse (Again from the review state). */
    fun nextStabilityOnForget(
        stability: Double,
        difficulty: Double,
        retrievability: Double,
        w: List<Double>,
    ): Double {
        val s = w[11] * difficulty.pow(-w[12]) * ((stability + 1).pow(w[13]) - 1) *
            exp((1 - retrievability) * w[14])
        return maxOf(s, 0.1)
    }

    fun isSameDayReview(elapsedDays: Double): Boolean = elapsedDays <= 0

    /** Next interval (days) for a target retention. */
    fun nextInterval(
        stability: Double,
        desiredRetention: Double,
        maximumDays: Int,
        w: List<Double>,
    ): Int {
        val d = decay(w)
        val f = factor(w)
        val interval = (stability / f) * (desiredRetention.pow(1.0 / d) - 1)
        return minOf(maxOf(Math.round(interval).toInt(), 1), maximumDays)
    }

    private fun clamp(value: Double, minValue: Double, maxValue: Double): Double =
        maxOf(minValue, minOf(value, maxValue))
}
