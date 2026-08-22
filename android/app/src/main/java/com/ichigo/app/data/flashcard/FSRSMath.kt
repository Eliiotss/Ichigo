package com.ichigo.app.data.flashcard

import kotlin.math.exp
import kotlin.math.pow

/**
 * The official FSRS-6 spaced-repetition formulas.
 *
 * Reference implementation followed: `py-fsrs` / the FSRS wiki equations for
 * FSRS-6 (21 weights, `w[20]` = trainable decay). Every formula below is the
 * published one; where this app deliberately differs from the reference, the
 * difference is documented at the call site in [FlashcardReviewEngine]
 * ("cara A" graduation), never hidden inside the maths.
 */
object FSRSMath {

    /** Lower bound for stability. Kept at the value the app has always used. */
    const val STABILITY_FLOOR = 0.1

    /** Upper bound for stability (FSRS reference clamp, in days). */
    const val STABILITY_CEILING = 36_500.0

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
        maxOf(w[grade.value - 1], STABILITY_FLOOR)

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

    /** Stability after a successful recall (Hard/Good/Easy) on a later day. */
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
        return clamp(stability * (1 + increase), STABILITY_FLOOR, STABILITY_CEILING)
    }

    /**
     * FSRS-6 short-term (same-day) stability:
     *
     *     S' = S · e^(w17 · (G − 3 + w18)) · S^(−w19)
     *
     * FSRS-6 additionally requires that a same-day Good/Easy never *lowers*
     * stability, hence the `max(increase, 1)` guard for G ≥ 3.
     *
     * This is what a review inside the learning/relearning steps uses. Before
     * this existed the engine reset stability to [initialStability] on every
     * learning step, which threw away the card's history.
     */
    fun shortTermStability(stability: Double, grade: FlashcardGrade, w: List<Double>): Double {
        val s = maxOf(stability, STABILITY_FLOOR)
        // Presets shorter than 20 weights predate FSRS-6 short-term memory;
        // leaving S untouched is the safe fallback (never NaN, never a jump).
        if (w.size <= 19) return s
        var increase = s.pow(-w[19]) * exp(w[17] * (grade.value - 3 + w[18]))
        if (grade.value >= FlashcardGrade.GOOD.value) increase = maxOf(increase, 1.0)
        return clamp(s * increase, STABILITY_FLOOR, STABILITY_CEILING)
    }

    /**
     * Stability after a lapse (Again from the review state).
     *
     * FSRS-6 clamps the long-term post-lapse value with the short-term one,
     * `min(S_forget, S / e^(w17·w18))`, so forgetting a card can never *raise*
     * its stability. That clamp was missing here before.
     */
    fun nextStabilityOnForget(
        stability: Double,
        difficulty: Double,
        retrievability: Double,
        w: List<Double>,
    ): Double {
        val longTerm = w[11] * difficulty.pow(-w[12]) * ((stability + 1).pow(w[13]) - 1) *
            exp((1 - retrievability) * w[14])
        val shortTerm = if (w.size > 18) stability / exp(w[17] * w[18]) else Double.MAX_VALUE
        return clamp(minOf(longTerm, shortTerm), STABILITY_FLOOR, STABILITY_CEILING)
    }

    /** True when the review happens on the same day as the previous one. */
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
        if (interval.isNaN()) return 1
        return minOf(maxOf(Math.round(interval).toInt(), 1), maximumDays)
    }

    private fun clamp(value: Double, minValue: Double, maxValue: Double): Double =
        maxOf(minValue, minOf(value, maxValue))
}
