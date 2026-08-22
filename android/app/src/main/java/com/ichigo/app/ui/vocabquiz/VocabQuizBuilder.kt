package com.ichigo.app.ui.vocabquiz

import com.ichigo.app.data.model.VocabularyItem
import kotlin.random.Random

/**
 * One multiple-choice question: the word's kanji is the prompt, the four choices
 * are readings (furigana), and [meaning] is revealed under the reading once the
 * user answers — exactly the "食べる → pilih bacaan, lalu arti muncul" flow.
 */
data class VocabQuizQuestion(
    val wordId: String,
    val kanji: String,
    val choices: List<String>,
    val correctAnswer: String,
    val meaning: String,
)

/**
 * Pure, deterministic (given an [Random]) question builder for the Vocab quiz —
 * no Android, no I/O, so it is unit-tested directly. Kept separate from the
 * ViewModel/repository like `FlashcardDeckQueueBuilder`.
 *
 * The selection is **adaptive ("fokus jawaban salah")**: words answered wrong
 * come back first, then never-quizzed words, then in-progress, then mastered —
 * driven by the per-word quiz score persisted in `quiz_result`.
 */
object VocabQuizBuilder {

    /** A word counts as quiz-mastered once its score reaches this. */
    const val MASTERED_THRESHOLD = 2
    /** Choices per question (1 correct + up to 3 distractors). */
    const val OPTIONS = 4

    /**
     * Words usable in a kanji→reading quiz: they must carry a real kanji that is
     * distinct from the reading (pure-kana words like `びっくり` are skipped —
     * there is nothing to "read").
     */
    fun eligible(items: List<VocabularyItem>): List<VocabularyItem> =
        items.filter { it.kanji.isNotBlank() && it.hiragana.isNotBlank() && it.kanji != it.hiragana }

    /**
     * New score after an answer: a correct answer raises it (`max(score,0)+1`);
     * a wrong answer drops it to `-1` ("needs review"). `current == null` means
     * the word was never quizzed.
     */
    fun nextScore(current: Int?, correct: Boolean): Int =
        if (correct) maxOf(current ?: 0, 0) + 1 else -1

    /**
     * Adaptive order over the eligible words: wrong (`score < 0`) → new (never
     * quizzed / `0`) → learning (`1 until threshold`) → mastered (`>= threshold`),
     * each group shuffled with [rng]. Returns at most [count] words.
     */
    fun select(
        items: List<VocabularyItem>,
        scores: Map<String, Int>,
        count: Int,
        rng: Random,
    ): List<VocabularyItem> {
        val wrong = ArrayList<VocabularyItem>()
        val fresh = ArrayList<VocabularyItem>()
        val learning = ArrayList<VocabularyItem>()
        val mastered = ArrayList<VocabularyItem>()
        for (item in eligible(items)) {
            val s = scores[item.id]
            when {
                s == null || s == 0 -> fresh
                s < 0 -> wrong
                s < MASTERED_THRESHOLD -> learning
                else -> mastered
            }.add(item)
        }
        val ordered = wrong.shuffled(rng) + fresh.shuffled(rng) + learning.shuffled(rng) + mastered.shuffled(rng)
        return ordered.take(count.coerceAtLeast(0))
    }

    /** Builds one question: the correct reading plus up to 3 distinct distractor readings. */
    fun makeQuestion(item: VocabularyItem, pool: List<VocabularyItem>, rng: Random): VocabQuizQuestion {
        val correct = item.hiragana
        val distractors = pool.asSequence()
            .map { it.hiragana }
            .filter { it.isNotBlank() && it != correct }
            .distinct()
            .toMutableList()
            .apply { shuffle(rng) }
            .take(OPTIONS - 1)
        val choices = (distractors + correct).shuffled(rng)
        return VocabQuizQuestion(item.id, item.kanji, choices, correct, item.arti)
    }

    /** A full round: adaptive selection, then one question per selected word. */
    fun buildRound(
        items: List<VocabularyItem>,
        scores: Map<String, Int>,
        count: Int,
        rng: Random,
    ): List<VocabQuizQuestion> {
        val pool = eligible(items)
        return select(items, scores, count, rng).map { makeQuestion(it, pool, rng) }
    }
}
