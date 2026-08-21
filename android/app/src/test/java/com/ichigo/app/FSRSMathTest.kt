package com.ichigo.app

import com.ichigo.app.data.flashcard.FSRSMath
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardSettings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.exp
import kotlin.math.pow

/**
 * Conformance tests for the FSRS-6 formulas.
 *
 * These lock the two rules that were missing before:
 *  1. a lapse can never *raise* a card's stability
 *     (`min(S_forget, S / e^(w17·w18))`), and
 *  2. same-day reviews use short-term stability
 *     (`S' = S · e^(w17·(G−3+w18)) · S^(−w19)`, never shrinking on Good/Easy).
 *
 * Pure JVM, default (official) weights.
 */
class FSRSMathTest {

    private val w = FlashcardSettings().fsrsWeights

    @Test
    fun defaultPresetHasTheTwentyOneFsrs6Weights() {
        assertEquals(21, w.size)
    }

    // -- Retrievability / interval -------------------------------------------

    @Test
    fun retrievabilityIsNinetyPercentAfterExactlyOneStability() {
        // The FSRS-6 forgetting curve is normalised so R(t = S) = 0.9.
        for (s in listOf(1.0, 7.0, 30.0, 365.0)) {
            assertEquals(0.9, FSRSMath.retrievability(s, s, w), 1e-9)
        }
    }

    @Test
    fun intervalAtNinetyPercentRetentionEqualsStability() {
        // Same normalisation seen from the other side: desired retention 0.9
        // means "come back when R has decayed to 0.9", i.e. after S days.
        for (s in listOf(1.0, 10.0, 21.0, 180.0)) {
            assertEquals(s.toInt(), FSRSMath.nextInterval(s, 0.9, 36500, w))
        }
    }

    @Test
    fun intervalIsClampedToAtLeastOneDayAndAtMostTheMaximum() {
        assertEquals(1, FSRSMath.nextInterval(0.01, 0.9, 36500, w))
        assertEquals(30, FSRSMath.nextInterval(10_000.0, 0.9, 30, w))
    }

    // -- Difficulty -----------------------------------------------------------

    @Test
    fun difficultyStaysInsideOneToTen() {
        for (grade in FlashcardGrade.allCases) {
            for (d in listOf(1.0, 5.0, 10.0)) {
                val next = FSRSMath.nextDifficulty(d, grade, w)
                assertTrue("D=$next out of range", next in 1.0..10.0)
            }
            val d0 = FSRSMath.initialDifficulty(grade, w)
            assertTrue("D0=$d0 out of range", d0 in 1.0..10.0)
        }
    }

    @Test
    fun againRaisesDifficulty_easyLowersIt() {
        val base = 5.0
        assertTrue(FSRSMath.nextDifficulty(base, FlashcardGrade.AGAIN, w) > base)
        assertTrue(FSRSMath.nextDifficulty(base, FlashcardGrade.EASY, w) < base)
    }

    // -- Post-lapse stability (the missing FSRS-6 clamp) ----------------------

    @Test
    fun lapseNeverIncreasesStability() {
        // Regression: with the clamp missing, a short-stability card reviewed
        // long after it was due (low R) came out of a lapse with MORE stability
        // than it had before — forgetting made the interval longer.
        val cap = 1.0 / exp(w[17] * w[18])
        for (s in listOf(0.1, 0.5, 1.0, 2.0, 10.0, 60.0)) {
            for (d in listOf(1.0, 5.0, 10.0)) {
                for (r in listOf(0.05, 0.1, 0.2, 0.5, 0.9)) {
                    val next = FSRSMath.nextStabilityOnForget(s, d, r, w)
                    assertTrue("S=$s D=$d R=$r → $next grew", next <= s + 1e-9)
                    // The short-term cap binds unless the stability floor does.
                    val bound = maxOf(s * cap, FSRSMath.STABILITY_FLOOR)
                    assertTrue("S=$s D=$d R=$r → $next above short-term cap", next <= bound + 1e-9)
                }
            }
        }
    }

    @Test
    fun lapseOnAnOverdueCardIsClampedToTheShortTermValue() {
        // S = 1 day, D = 5, R = 0.1 → the long-term formula alone yields ~1.184.
        val clamped = FSRSMath.nextStabilityOnForget(1.0, 5.0, 0.1, w)
        assertEquals(1.0 / exp(w[17] * w[18]), clamped, 1e-9)
        assertTrue(clamped < 1.0)
    }

    @Test
    fun lapseStabilityNeverFallsBelowTheFloor() {
        val next = FSRSMath.nextStabilityOnForget(0.1, 10.0, 0.99, w)
        assertTrue(next >= FSRSMath.STABILITY_FLOOR)
    }

    // -- Short-term (same-day) stability --------------------------------------

    @Test
    fun shortTermMatchesTheFsrs6Formula() {
        val s = 5.0
        for (grade in listOf(FlashcardGrade.AGAIN, FlashcardGrade.HARD)) {
            val expected = s * s.pow(-w[19]) * exp(w[17] * (grade.value - 3 + w[18]))
            assertEquals(expected, FSRSMath.shortTermStability(s, grade, w), 1e-9)
        }
    }

    @Test
    fun shortTermNeverShrinksOnGoodOrEasy() {
        for (s in listOf(0.1, 1.0, 5.0, 50.0, 500.0)) {
            assertTrue(FSRSMath.shortTermStability(s, FlashcardGrade.GOOD, w) >= s - 1e-9)
            assertTrue(FSRSMath.shortTermStability(s, FlashcardGrade.EASY, w) >= s - 1e-9)
        }
    }

    @Test
    fun shortTermIsMonotonicAcrossGrades() {
        val s = 3.0
        val again = FSRSMath.shortTermStability(s, FlashcardGrade.AGAIN, w)
        val hard = FSRSMath.shortTermStability(s, FlashcardGrade.HARD, w)
        val good = FSRSMath.shortTermStability(s, FlashcardGrade.GOOD, w)
        val easy = FSRSMath.shortTermStability(s, FlashcardGrade.EASY, w)
        assertTrue(again < hard)
        assertTrue(hard < good)
        assertTrue(good < easy)
    }

    @Test
    fun shortTermIsFiniteForDegenerateStability() {
        // Legacy rows can carry stability 0.0; S^(-w19) would be +Infinity there,
        // so the floor must be applied before the power.
        for (grade in FlashcardGrade.allCases) {
            val next = FSRSMath.shortTermStability(0.0, grade, w)
            assertTrue("not finite: $next", next.isFinite())
            assertTrue(next >= FSRSMath.STABILITY_FLOOR)
        }
    }

    @Test
    fun shortTermFallsBackSafelyForAPreFsrs6Preset() {
        val shortPreset = w.take(17)
        assertEquals(4.0, FSRSMath.shortTermStability(4.0, FlashcardGrade.GOOD, shortPreset), 1e-9)
    }

    // -- Recall stability -----------------------------------------------------

    @Test
    fun recallGrowsStability_andEasyGrowsItMostHardLeast() {
        val s = 10.0
        val d = 5.0
        val r = 0.9
        val hard = FSRSMath.nextStabilityOnRecall(s, d, r, FlashcardGrade.HARD, w)
        val good = FSRSMath.nextStabilityOnRecall(s, d, r, FlashcardGrade.GOOD, w)
        val easy = FSRSMath.nextStabilityOnRecall(s, d, r, FlashcardGrade.EASY, w)
        assertTrue(hard > s)
        assertTrue(hard < good)
        assertTrue(good < easy)
    }
}
