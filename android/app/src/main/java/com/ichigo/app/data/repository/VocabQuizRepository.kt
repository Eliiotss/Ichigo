package com.ichigo.app.data.repository

import com.ichigo.app.data.local.dao.QuizResultDao
import com.ichigo.app.data.local.entity.QuizResultEntity
import com.ichigo.app.ui.vocabquiz.VocabQuizBuilder
import com.ichigo.app.ui.vocabquiz.VocabQuizQuestion
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.random.Random

/**
 * Backs the Vocab multiple-choice quiz. Loads the level's vocab (reusing
 * [ContentRepository]) and the per-word quiz scores (`quiz_result`), builds an
 * adaptive round via [VocabQuizBuilder], and records each answer.
 *
 * Deliberately **independent of FSRS** — it never reads or writes the `progress`
 * table, streaks or analytics, so the quiz cannot disturb spaced repetition.
 */
@Singleton
class VocabQuizRepository @Inject constructor(
    private val content: ContentRepository,
    private val quizDao: QuizResultDao,
) {
    /** Builds one adaptive round of [count] questions for a level. */
    suspend fun buildRound(jsonFile: String, count: Int, rng: Random = Random.Default): List<VocabQuizQuestion> {
        val items = content.loadVocab(jsonFile)
        val scores = quizDao.getAll().associate { it.wordId to it.score }
        return VocabQuizBuilder.buildRound(items, scores, count, rng)
    }

    /** Updates a word's quiz score so wrong answers resurface and mastered ones step back. */
    suspend fun record(wordId: String, correct: Boolean) {
        val current = quizDao.get(wordId)?.score
        quizDao.upsert(
            QuizResultEntity(wordId, VocabQuizBuilder.nextScore(current, correct), System.currentTimeMillis()),
        )
    }

    /** Wipes all quiz progress (called from "Reset Semua Progress"). */
    suspend fun clearAll() = quizDao.deleteAll()
}
