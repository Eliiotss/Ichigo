package com.ichigo.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardProgress
import com.ichigo.app.data.flashcard.FlashcardReviewLog

/**
 * Room tables that replace the iOS `UserDefaults`-backed stores. Each entity maps
 * one-to-one to its business model, so the same data is persisted with the same
 * field names — only the storage engine differs (SQLite vs. property list).
 */

/** Replaces `flashcard_progress_v1` ([String: FlashcardProgress]). */
@Entity(tableName = "progress")
data class ProgressEntity(
    @PrimaryKey val id: String,
    val level: String,
    val front: String,
    val back: String,
    val state: String,
    val dueDate: Long,
    val stability: Double,
    val difficulty: Double,
    val reps: Int,
    val lapses: Int,
    val lastReview: Long?,
    val scheduledDays: Int,
    val learningStepIndex: Int,
) {
    fun toDomain() = FlashcardProgress(
        id = id, level = level, front = front, back = back,
        state = FlashcardCardState.from(state), dueDate = dueDate,
        stability = stability, difficulty = difficulty, reps = reps, lapses = lapses,
        lastReview = lastReview, scheduledDays = scheduledDays, learningStepIndex = learningStepIndex,
    )

    companion object {
        fun from(p: FlashcardProgress) = ProgressEntity(
            id = p.id, level = p.level, front = p.front, back = p.back,
            state = p.state.raw, dueDate = p.dueDate,
            stability = p.stability, difficulty = p.difficulty, reps = p.reps, lapses = p.lapses,
            lastReview = p.lastReview, scheduledDays = p.scheduledDays, learningStepIndex = p.learningStepIndex,
        )
    }
}

/** Replaces `flashcard_reviews_v1` ([FlashcardReviewLog], capped at 20 000). */
@Entity(tableName = "review_logs")
data class ReviewLogEntity(
    @PrimaryKey(autoGenerate = true) val seq: Long = 0,
    val logId: String,
    val cardId: String,
    val levelId: String,
    val grade: Int,
    val reviewedAt: Long,
    val nextDueDate: Long,
    val state: String,
) {
    companion object {
        fun from(l: FlashcardReviewLog) = ReviewLogEntity(
            logId = l.id, cardId = l.cardId, levelId = l.levelId,
            grade = l.grade.value, reviewedAt = l.reviewedAt, nextDueDate = l.nextDueDate, state = l.state.raw,
        )
    }
}

/** Replaces `hiraganaCount` / `katakanaCount` ([String: Int]). script = "hira"/"kata". */
@Entity(tableName = "kana_count", primaryKeys = ["kana", "script"])
data class KanaCountEntity(
    val kana: String,
    val script: String,
    val count: Int,
)

/** Replaces the per-day `flashcard_new_today_<levelKey>_<day>` string lists. */
@Entity(tableName = "new_card_today", primaryKeys = ["levelKey", "day", "cardId"])
data class NewCardTodayEntity(
    val levelKey: String,
    val day: String,
    val cardId: String,
)

/**
 * Query projection only (not a table): how many new cards were started today per
 * deck. Lets the Home/Profile totals apply the **per-deck** daily quota with a
 * single grouped query instead of one query per deck.
 */
data class NewCardDayCount(
    val levelKey: String,
    val total: Int,
)

/**
 * Per-word progress for the **Vocab multiple-choice quiz** — deliberately kept
 * SEPARATE from the FSRS `progress` table so the quiz never touches spaced
 * repetition, streaks or mastery. [score] drives the adaptive "focus on wrong"
 * selection: a correct answer raises it (`max(score,0)+1`), a wrong answer sets
 * it to `-1` ("needs review"); a word counts as quiz-mastered at
 * `score >= MASTERED_THRESHOLD`. Added in DB version 2 (see Migration 1→2).
 */
@Entity(tableName = "quiz_result")
data class QuizResultEntity(
    @PrimaryKey val wordId: String,
    val score: Int,
    val lastAnswered: Long,
)
