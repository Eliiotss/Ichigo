package com.ichigo.app

import com.ichigo.app.data.model.VocabularyItem
import com.ichigo.app.ui.vocabquiz.VocabQuizBuilder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/**
 * Locks the Vocab-quiz question logic: eligibility, 4-option questions, the
 * adaptive "focus on wrong" ordering, and the per-word scoring. Pure JVM.
 */
class VocabQuizBuilderTest {

    private fun v(id: String, kanji: String, hiragana: String, arti: String = "arti-$id") =
        VocabularyItem(id = id, kanji = kanji, hiragana = hiragana, arti = arti)

    private val seeded get() = Random(42)

    // A pool with distinct readings so questions can always fill 4 options.
    private val pool = listOf(
        v("a", "食べる", "たべる"), v("b", "飲む", "のむ"), v("c", "行く", "いく"),
        v("d", "見る", "みる"), v("e", "話す", "はなす"), v("f", "書く", "かく"),
    )

    @Test
    fun eligibleSkipsKanaOnlyAndReadingEqualsKanji() {
        val items = pool + listOf(
            v("kana", "びっくり", "びっくり"),  // kanji == hiragana → skip
            v("empty", "", "あああ"),            // no kanji → skip
        )
        val ids = VocabQuizBuilder.eligible(items).map { it.id }.toSet()
        assertEquals(pool.map { it.id }.toSet(), ids)
    }

    @Test
    fun questionHasFourUniqueChoicesIncludingCorrectAndMeaning() {
        val item = pool.first()
        val q = VocabQuizBuilder.makeQuestion(item, pool, seeded)
        assertEquals("食べる", q.kanji)
        assertEquals("たべる", q.correctAnswer)
        assertEquals("arti-a", q.meaning)
        assertEquals(4, q.choices.size)
        assertEquals("no duplicate options", 4, q.choices.toSet().size)
        assertTrue("correct reading is among the options", "たべる" in q.choices)
    }

    @Test
    fun wrongWordIsSelectedBeforeNewOrMastered() {
        val scores = mapOf("c" to -1, "a" to 5, "b" to 5) // c wrong; a,b mastered; rest new
        val picked = VocabQuizBuilder.select(pool, scores, count = 1, rng = seeded)
        assertEquals(listOf("c"), picked.map { it.id })
    }

    @Test
    fun masteredWordsAreDeprioritised() {
        // 4 eligible are mastered, 2 are new; asking for 2 must return only the new ones.
        val scores = mapOf("a" to 2, "b" to 2, "c" to 2, "d" to 2)
        val picked = VocabQuizBuilder.select(pool, scores, count = 2, rng = seeded).map { it.id }.toSet()
        assertEquals(setOf("e", "f"), picked)
    }

    @Test
    fun buildRoundHonoursCountAndFocusesWrongFirst() {
        val scores = mapOf("e" to -1, "f" to -1) // two wrong
        val round = VocabQuizBuilder.buildRound(pool, scores, count = 3, rng = seeded)
        assertEquals(3, round.size)
        val firstTwo = round.take(2).map { it.wordId }.toSet()
        assertEquals("wrong words lead the round", setOf("e", "f"), firstTwo)
        round.forEach { assertEquals(4, it.choices.size) }
    }

    @Test
    fun nextScoreRaisesOnCorrectAndDropsToMinusOneOnWrong() {
        assertEquals(1, VocabQuizBuilder.nextScore(null, correct = true))   // new + correct
        assertEquals(1, VocabQuizBuilder.nextScore(-1, correct = true))     // was wrong, now right
        assertEquals(2, VocabQuizBuilder.nextScore(1, correct = true))      // learning → mastered
        assertEquals(-1, VocabQuizBuilder.nextScore(5, correct = false))    // mastered, missed → review
    }

    @Test
    fun buildRoundStaysEmptyWhenNoEligibleWords() {
        val kanaOnly = listOf(v("x", "", "あ"), v("y", "びっくり", "びっくり"))
        assertTrue(VocabQuizBuilder.buildRound(kanaOnly, emptyMap(), count = 5, rng = seeded).isEmpty())
    }
}
