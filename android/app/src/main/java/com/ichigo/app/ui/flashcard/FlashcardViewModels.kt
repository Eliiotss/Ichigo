package com.ichigo.app.ui.flashcard

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardDeckCard
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardLoadState
import com.ichigo.app.data.flashcard.FlashcardMode
import com.ichigo.app.data.flashcard.flashcardLevelKey
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.repository.FlashcardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Port of `FlashcardLevelView`'s data: loads every unlocked deck for the mode and
 * exposes per-level total/due counts, refreshed whenever progress changes.
 */
@HiltViewModel
class FlashcardLevelViewModel @Inject constructor(
    private val flashcards: FlashcardRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    val mode: FlashcardMode = FlashcardMode.entries.first { it.raw == (handle["mode"] ?: "vocabulary") }
    val levels: List<ContentLevel> = mode.levels()

    val stats: StateFlow<Map<String, FlashcardRepository.LevelStats>> = flow {
        for (level in levels) if (!level.isLocked) flashcards.loadDeck(mode, level.id, level.jsonFile)
        flashcards.progress.collect {
            emit(
                levels.filter { !it.isLocked }
                    .mapNotNull { lv -> flashcards.deckStats(mode, lv.id)?.let { lv.id to it } }
                    .toMap(),
            )
        }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyMap())
}

data class SessionUiState(
    val loadState: FlashcardLoadState = FlashcardLoadState.Idle,
    val levelId: String = "",
    val modeTitle: String = "",
    val currentCard: FlashcardDeckCard? = null,
    val positionText: String = "Kartu 0 / 0",
    val progressValue: Float = 0f,
    val isRevealed: Boolean = false,
    val finished: Boolean = false,
    val remainingNew: Int = 0,
    val remainingLearning: Int = 0,
    val remainingReview: Int = 0,
    val isSubmitting: Boolean = false,
    val sessionCorrect: Int = 0,
    val sessionWrong: Int = 0,
    val sessionTotal: Int = 0,
    val currentStreak: Int = 0,
) {
    val sessionAnswered: Int get() = sessionCorrect + sessionWrong
    val sessionAccuracy: Double get() = if (sessionAnswered == 0) 0.0 else sessionCorrect.toDouble() / sessionAnswered
}

private enum class SessionBucket { NEW, LEARNING, REVIEW }

/**
 * Direct port of `FlashcardDeckSessionViewModel`.
 *
 * Every rule is preserved: the daily new-card quota follows the "Target Harian"
 * setting, tapping a grade both scores and advances (no separate Next button), an
 * "Ulang" card is re-appended to the queue, and the three count pills (due / ulang
 * / hafal) are driven by the same per-session bucket logic as iOS.
 */
@HiltViewModel
class FlashcardSessionViewModel @Inject constructor(
    private val flashcards: FlashcardRepository,
    private val prefs: AppPreferences,
    handle: SavedStateHandle,
) : ViewModel() {

    private val mode: FlashcardMode = FlashcardMode.entries.first { it.raw == (handle["mode"] ?: "vocabulary") }
    private val levelId: String = handle["levelId"] ?: ""
    private val jsonFile: String = handle["jsonFile"] ?: ""
    private val levelKey: String = flashcardLevelKey(mode, levelId)

    private val _state = MutableStateFlow(SessionUiState(levelId = levelId, modeTitle = mode.title))
    val state: StateFlow<SessionUiState> = _state.asStateFlow()

    // Mutable session state, mirroring the Swift @Published fields.
    private var queue: MutableList<FlashcardDeckCard> = mutableListOf()
    private var currentIndex = 0
    private var sessionTotal = 0
    private var remainingNew = 0
    private var remainingLearning = 0
    private var remainingReview = 0
    private var isRevealed = false
    private var finished = false
    private var sessionCorrect = 0
    private var sessionWrong = 0
    private var isSubmitting = false
    private var streakValue = 0

    private val cardBucket = HashMap<String, SessionBucket>()
    private val retryCardIds = HashSet<String>()

    init {
        viewModelScope.launch { streakValue = prefs.streak.first(); push() }
        loadDeck()
    }

    private fun loadDeck() {
        _state.value = _state.value.copy(loadState = FlashcardLoadState.Loading)
        viewModelScope.launch {
            flashcards.ensureLoaded()
            val items = flashcards.loadDeck(mode, levelId, jsonFile)
            if (items.isEmpty()) {
                _state.value = _state.value.copy(loadState = FlashcardLoadState.Empty)
                return@launch
            }
            val target = prefs.dailyTargetNow()
            val built = flashcards.buildQueue(mode, levelId, items, target)

            queue = built.toMutableList()
            sessionTotal = queue.size
            cardBucket.clear(); retryCardIds.clear()
            remainingNew = 0; remainingLearning = 0; remainingReview = 0
            for (card in queue) {
                val bucket = when (flashcards.deckProgress(card, levelKey).state) {
                    FlashcardCardState.NEW -> SessionBucket.NEW.also { remainingNew++ }
                    FlashcardCardState.LEARNING, FlashcardCardState.RELEARNING -> SessionBucket.LEARNING.also { remainingLearning++ }
                    FlashcardCardState.REVIEW -> SessionBucket.REVIEW.also { remainingReview++ }
                }
                cardBucket[card.id] = bucket
            }
            currentIndex = 0; sessionCorrect = 0; sessionWrong = 0
            isSubmitting = false; isRevealed = false
            finished = queue.isEmpty()
            streakValue = prefs.streak.first()
            _state.value = _state.value.copy(loadState = if (queue.isEmpty()) FlashcardLoadState.Empty else FlashcardLoadState.Loaded)
            push()
        }
    }

    private val currentCard: FlashcardDeckCard? get() = queue.getOrNull(currentIndex)

    fun reveal() {
        if (isRevealed) return
        isRevealed = true
        push()
    }

    /** Grade + advance in one tap (Swift `submit`). */
    fun submit(grade: FlashcardGrade) {
        if (isSubmitting || !isRevealed) return
        val card = currentCard ?: return
        isSubmitting = true

        when (grade) {
            FlashcardGrade.AGAIN -> {
                sessionWrong++
                if (retryCardIds.add(card.id)) queue.add(card)
            }
            else -> sessionCorrect++
        }
        push()

        viewModelScope.launch {
            val stateAfter = flashcards.review(card, levelKey, grade)
            applyBucketDelta(card.id, stateAfter)
            advanceAfterGrade()
            streakValue = prefs.streak.first()
            isSubmitting = false
            push()
        }
    }

    private fun advanceAfterGrade() {
        if (currentIndex + 1 >= queue.size) {
            finished = true
            return
        }
        currentIndex += 1
        isRevealed = false
    }

    // Universal counter rule, identical to Swift `applyBucketDelta`.
    private fun applyBucketDelta(cardId: String, stateAfter: FlashcardCardState) {
        val bucket = cardBucket[cardId] ?: return
        if (stateAfter == FlashcardCardState.REVIEW) {
            decrement(bucket)
            cardBucket.remove(cardId)
        } else {
            if (bucket != SessionBucket.LEARNING) {
                decrement(bucket)
                remainingLearning++
                cardBucket[cardId] = SessionBucket.LEARNING
            }
        }
    }

    private fun decrement(bucket: SessionBucket) {
        when (bucket) {
            SessionBucket.NEW -> remainingNew = maxOf(0, remainingNew - 1)
            SessionBucket.LEARNING -> remainingLearning = maxOf(0, remainingLearning - 1)
            SessionBucket.REVIEW -> remainingReview = maxOf(0, remainingReview - 1)
        }
    }

    private fun positionText(): String =
        if (sessionTotal == 0) "Kartu 0 / 0" else "Kartu ${minOf(currentIndex + 1, sessionTotal)} / $sessionTotal"

    private fun progressValue(): Float =
        if (sessionTotal == 0) 0f else minOf(currentIndex + 1, sessionTotal).toFloat() / sessionTotal

    private fun push() {
        _state.value = _state.value.copy(
            levelId = levelId,
            modeTitle = mode.title,
            currentCard = currentCard,
            positionText = positionText(),
            progressValue = progressValue(),
            isRevealed = isRevealed,
            finished = finished,
            remainingNew = remainingNew,
            remainingLearning = remainingLearning,
            remainingReview = remainingReview,
            isSubmitting = isSubmitting,
            sessionCorrect = sessionCorrect,
            sessionWrong = sessionWrong,
            sessionTotal = sessionTotal,
            currentStreak = streakValue,
        )
    }
}
