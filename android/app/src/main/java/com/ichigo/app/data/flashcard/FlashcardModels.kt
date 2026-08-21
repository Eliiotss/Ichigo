package com.ichigo.app.data.flashcard

import androidx.compose.ui.graphics.Color
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.VocabularyItem
import com.ichigo.app.data.model.grammarLevels
import com.ichigo.app.data.model.vocabularyLevels
import com.ichigo.app.ui.theme.IchigoPalette

/** UI load state, port of `FlashcardLoadState`. */
sealed interface FlashcardLoadState {
    data object Idle : FlashcardLoadState
    data object Loading : FlashcardLoadState
    data object Loaded : FlashcardLoadState
    data object Empty : FlashcardLoadState
    data object ComingSoon : FlashcardLoadState
    data class Failed(val message: String) : FlashcardLoadState
}

/** Port of `FlashcardCardState` (raw string values preserved for storage). */
enum class FlashcardCardState(val raw: String) {
    NEW("new"),
    LEARNING("learning"),
    REVIEW("review"),
    RELEARNING("relearning");

    companion object {
        fun from(raw: String): FlashcardCardState = entries.firstOrNull { it.raw == raw } ?: NEW
    }
}

/** Port of `FlashcardGrade`. Raw ints (1..4) preserved to match logs and FSRS indexing. */
enum class FlashcardGrade(val value: Int) {
    AGAIN(1),
    HARD(2),
    GOOD(3),
    EASY(4);

    val title: String
        get() = when (this) {
            AGAIN -> "Ulang"
            HARD -> "Susah"
            GOOD -> "Bagus"
            EASY -> "Mudah"
        }

    companion object {
        val allCases = entries.toList()
        fun from(value: Int): FlashcardGrade = entries.firstOrNull { it.value == value } ?: GOOD
    }
}

/**
 * Port of `FlashcardSettings`. Defaults match iOS — including the 21 official
 * FSRS-6 weights — so scheduling stays aligned, with one intentional tweak:
 * [easyIntervalDays] is tuned to 3 days (iOS: 4) so "Mudah" cards return sooner.
 */
data class FlashcardSettings(
    var newCardsPerDay: Int = 35,
    var maxReviewsPerDay: Int = 9999,
    var learningStepsMinutes: List<Double> = listOf(1.0, 10.0),
    var relearningStepsMinutes: List<Double> = listOf(10.0),
    var desiredRetention: Double = 0.9,
    var maximumIntervalDays: Int = 36500,
    var graduatingIntervalDays: Int = 1,
    // Tuned to 3 days (iOS uses 4): a shorter first interval for "Mudah" cards
    // brings them back sooner so they are less likely to be forgotten.
    var easyIntervalDays: Int = 3,
    var leechThreshold: Int = 8,
    var fsrsWeights: List<Double> = listOf(
        0.2120, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.0010,
        1.8722, 0.1666, 0.7960, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ),
)

/**
 * Port of `FlashcardProgress`. Dates are epoch-millis [Long] (Room-friendly)
 * instead of Swift `Date`; the [isDue]/[isMastered] rules are unchanged.
 */
data class FlashcardProgress(
    val id: String,
    val level: String,
    val front: String,
    val back: String,
    var state: FlashcardCardState,
    var dueDate: Long,
    var stability: Double,
    var difficulty: Double,
    var reps: Int,
    var lapses: Int,
    var lastReview: Long?,
    var scheduledDays: Int,
    var learningStepIndex: Int,
) {
    fun isDue(now: Long = System.currentTimeMillis()): Boolean = dueDate <= now
    val isMastered: Boolean
        get() = state == FlashcardCardState.REVIEW && scheduledDays >= MASTERED_MIN_SCHEDULED_DAYS

    companion object {
        /**
         * Interval at which a card counts as "hafal". Shared with the SQL in
         * `ProgressDao.countMastered` — change both together.
         */
        const val MASTERED_MIN_SCHEDULED_DAYS = 21

        /** Fresh progress for an unseen card, equivalent to `init(deckCard:levelKey:)`. */
        fun newProgress(card: FlashcardDeckCard, levelKey: String, now: Long = System.currentTimeMillis()) =
            FlashcardProgress(
                id = card.id,
                level = levelKey,
                front = card.front,
                back = card.revealedBody,
                state = FlashcardCardState.NEW,
                dueDate = now,
                stability = 0.1,
                difficulty = 5.0,
                reps = 0,
                lapses = 0,
                lastReview = null,
                scheduledDays = 0,
                learningStepIndex = 0,
            )
    }
}

/** Port of `FlashcardReviewLog`. */
data class FlashcardReviewLog(
    val id: String,          // UUID string
    val cardId: String,
    val levelId: String,
    val grade: FlashcardGrade,
    val reviewedAt: Long,
    val nextDueDate: Long,
    val state: FlashcardCardState,
)

/** Port of `FlashcardAnalyticsSummary`. */
data class FlashcardAnalyticsSummary(
    var totalReviews: Int = 0,
    var againCount: Int = 0,
    var hardCount: Int = 0,
    var goodCount: Int = 0,
    var easyCount: Int = 0,
    var lastReviewedAt: Long? = null,
) {
    val accuracy: Double
        get() = if (totalReviews > 0) (hardCount + goodCount + easyCount).toDouble() / totalReviews else 0.0
}

/** Port of `FlashcardMode`. Colours/gradients kept from `AppTheme`. */
enum class FlashcardMode(val raw: String) {
    VOCABULARY("vocabulary"),
    GRAMMAR("grammar");

    val title: String get() = if (this == VOCABULARY) "Vocabulary" else "Grammar"
    val subtitle: String get() = if (this == VOCABULARY) "Hafalkan kosakata" else "Hafalkan pola kalimat"

    val color: Color get() = if (this == VOCABULARY) IchigoPalette.Blue else IchigoPalette.VioletDeep

    /** Icon gradient on the mode picker, values from the design. */
    val gradient: List<Color>
        get() = if (this == VOCABULARY) listOf(IchigoPalette.BlueLight, IchigoPalette.Blue)
        else listOf(IchigoPalette.Violet, IchigoPalette.VioletDeep)

    fun levels(): List<ContentLevel> = when (this) {
        VOCABULARY -> vocabularyLevels
        GRAMMAR -> grammarLevels
    }

    companion object {
        val allCases = entries.toList()
    }
}

/** Port of the free function `flashcardLevelKey(mode:levelId:)`. */
fun flashcardLevelKey(mode: FlashcardMode, levelId: String): String = "${mode.raw}_$levelId"

/**
 * Port of `FlashcardDeckCard`. `front` always shows; the rest is revealed on tap.
 * The two factory functions mirror the Swift `init(vocab:)` / `init(grammar:)`.
 */
data class FlashcardDeckCard(
    val id: String,
    val mode: FlashcardMode,
    val front: String,
    val revealedTitle: String,
    val revealedBody: String,
    val revealedTag: String,
) {
    companion object {
        fun fromVocab(item: VocabularyItem) = FlashcardDeckCard(
            id = item.id,
            mode = FlashcardMode.VOCABULARY,
            front = item.kanji,
            revealedTitle = item.hiragana,
            revealedBody = item.arti,
            revealedTag = item.jenisKata,
        )

        fun fromGrammar(item: GrammarItem) = FlashcardDeckCard(
            id = item.id,
            mode = FlashcardMode.GRAMMAR,
            front = item.pattern,
            revealedTitle = item.meaning,
            revealedBody = item.explanation.ifEmpty { item.meaning },
            revealedTag = if (item.structure.isEmpty()) item.tags.joinToString(" · ") else item.structure,
        )
    }
}
