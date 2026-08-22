package com.ichigo.app.ui.vocabquiz

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.repository.VocabQuizRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/** UI state for one Vocab-quiz session (mirrors `KanaFlashcardUiState`). */
data class VocabQuizUiState(
    val loading: Boolean = true,
    val empty: Boolean = false,
    val finished: Boolean = false,
    val currentIndex: Int = 0,
    val deckSize: Int = 0,
    val sessionCorrect: Int = 0,
    val question: VocabQuizQuestion? = null,
    val selectedAnswer: String? = null,
    val isAnswered: Boolean = false,
) {
    val progressValue: Float get() = if (deckSize == 0) 0f else currentIndex.toFloat() / deckSize
    val isLast: Boolean get() = currentIndex + 1 >= deckSize

    /** The word's meaning, shown under the furigana only after the user answers. */
    val revealedMeaning: String? get() = if (isAnswered) question?.meaning else null
}

/**
 * Drives the Vocab multiple-choice quiz. A round is drawn adaptively (wrong words
 * first) by [VocabQuizRepository]; each answer is recorded there. Nothing here
 * touches FSRS/streak — this is a standalone, score-based practice.
 */
@HiltViewModel
class VocabQuizViewModel @Inject constructor(
    private val repo: VocabQuizRepository,
    handle: SavedStateHandle,
) : ViewModel() {

    val levelId: String = handle["levelId"] ?: ""
    private val jsonFile: String = handle["jsonFile"] ?: ""

    private var deck: List<VocabQuizQuestion> = emptyList()
    private var currentIndex = 0
    private var sessionCorrect = 0
    private var selectedAnswer: String? = null
    private var isAnswered = false
    private var finished = false

    private val _state = MutableStateFlow(VocabQuizUiState())
    val state: StateFlow<VocabQuizUiState> = _state.asStateFlow()

    init { load() }

    private fun load() {
        _state.value = VocabQuizUiState(loading = true)
        viewModelScope.launch {
            deck = repo.buildRound(jsonFile, QUESTIONS_PER_ROUND)
            currentIndex = 0; sessionCorrect = 0
            selectedAnswer = null; isAnswered = false; finished = false
            if (deck.isEmpty()) _state.value = VocabQuizUiState(loading = false, empty = true) else push()
        }
    }

    fun handleAnswer(choice: String) {
        if (isAnswered) return
        val q = deck.getOrNull(currentIndex) ?: return
        selectedAnswer = choice
        isAnswered = true
        val correct = choice == q.correctAnswer
        if (correct) sessionCorrect++
        push()
        viewModelScope.launch { repo.record(q.wordId, correct) }
    }

    fun next() {
        if (currentIndex + 1 >= deck.size) {
            finished = true
        } else {
            currentIndex++
            selectedAnswer = null
            isAnswered = false
        }
        push()
    }

    /** Start another round (the "Ulangi" button on the finished screen). */
    fun restart() = load()

    private fun push() {
        _state.value = VocabQuizUiState(
            loading = false,
            empty = deck.isEmpty(),
            finished = finished,
            currentIndex = currentIndex,
            deckSize = deck.size,
            sessionCorrect = sessionCorrect,
            question = deck.getOrNull(currentIndex),
            selectedAnswer = selectedAnswer,
            isAnswered = isAnswered,
        )
    }

    companion object {
        /** Questions per round — adaptif, mudah diubah. */
        const val QUESTIONS_PER_ROUND = 20
    }
}
