package com.ichigo.app.ui.hiragana

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.model.KanaGroup
import com.ichigo.app.data.model.KanaItem
import com.ichigo.app.data.repository.ContentRepository
import com.ichigo.app.data.repository.KanaRepository
import com.ichigo.app.data.resource.ResourceLoader
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.math.ceil

/** UI state for the kana chart (Swift `HiraganaView`). */
data class HiraganaUiState(
    val isLoading: Boolean = true,
    val hiraganaGroups: List<KanaGroup> = emptyList(),
    val katakanaGroups: List<KanaGroup> = emptyList(),
    val selectedTab: Int = 0,
    val counts: Map<Pair<String, String>, Int> = emptyMap(),
) {
    val isKatakana: Boolean get() = selectedTab == 1
    val currentGroups: List<KanaGroup> get() = if (isKatakana) katakanaGroups else hiraganaGroups
    val currentFlat: List<KanaItem> get() = ResourceLoader.flatItems(currentGroups)
    val masteredCount: Int get() = KanaRepository.masteredCount(counts, currentFlat, isKatakana)
    val progressValue: Float get() = KanaRepository.progressPercent(counts, currentFlat, isKatakana).toFloat()
}

@HiltViewModel
class HiraganaViewModel @Inject constructor(
    content: ContentRepository,
    private val kana: KanaRepository,
) : ViewModel() {

    private val groups = MutableStateFlow<Pair<List<KanaGroup>, List<KanaGroup>>?>(null)
    private val selectedTab = MutableStateFlow(0)

    val state: StateFlow<HiraganaUiState> =
        combine(groups, kana.counts, selectedTab) { g, counts, tab ->
            if (g == null) HiraganaUiState(isLoading = true, counts = counts, selectedTab = tab)
            else HiraganaUiState(false, g.first, g.second, tab, counts)
        }.stateIn(viewModelScope, SharingStarted.Eagerly, HiraganaUiState())

    init {
        viewModelScope.launch {
            val all = content.loadKanaGroups()
            groups.value = all.filter { !it.isKatakanaScript } to all.filter { it.isKatakanaScript }
        }
    }

    fun setTab(tab: Int) { selectedTab.value = tab }
}

// ------------------------------------------------------------------------

/** A single quiz question, port of `FlashQuestion`. */
data class FlashQuestion(
    val cardKana: String,
    val choices: List<String>,
    val correctAnswer: String,
)

/** UI state for the kana flashcard quiz (Swift `HiraganaFlashcardView`). */
data class KanaFlashcardUiState(
    val isKatakana: Boolean = false,
    val deckEmpty: Boolean = false,
    val finished: Boolean = false,
    val currentIndex: Int = 0,
    val deckSize: Int = 0,
    val sessionCorrect: Int = 0,
    val question: FlashQuestion? = null,
    val selectedAnswer: String? = null,
    val isAnswered: Boolean = false,
    val masteredCount: Int = 0,
    val totalCount: Int = 0,
) {
    val progressValue: Float get() = if (deckSize == 0) 0f else currentIndex.toFloat() / deckSize
    val totalProgress: Float get() = if (totalCount == 0) 0f else masteredCount.toFloat() / totalCount
}

/**
 * Direct port of `HiraganaFlashcardView`'s logic: a 25-card session drawn from
 * not-yet-mastered kana first (topped up with mastered ones), four romaji
 * choices, and the 25×/−2 mastery tracking through [KanaRepository].
 */
@HiltViewModel
class KanaFlashcardViewModel @Inject constructor(
    private val content: ContentRepository,
    private val kana: KanaRepository,
    handle: SavedStateHandle,
) : ViewModel() {

    private val isKatakana: Boolean = (handle["isKatakana"] ?: "false").toBoolean()
    private val sessionSize = 25

    private var deck: List<KanaItem> = emptyList()
    private var deckFlat: List<KanaItem> = emptyList()   // full script list (distractor pool)
    private var progressFlat: List<KanaItem> = emptyList()
    private var currentIndex = 0
    private var sessionCorrect = 0
    private var finished = false
    private var selectedAnswer: String? = null
    private var isAnswered = false
    private var question: FlashQuestion? = null

    private val _state = MutableStateFlow(KanaFlashcardUiState(isKatakana = isKatakana))
    val state: StateFlow<KanaFlashcardUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch { buildDeck() }
    }

    private suspend fun buildDeck() {
        val all = content.loadKanaGroups()
        val currentGroups = all.filter { it.isKatakanaScript == isKatakana }
        val currentFlat = ResourceLoader.flatItems(currentGroups)
        progressFlat = currentFlat

        // Yōon unlock: full list once half the main kana are mastered.
        val mainGroups = currentGroups.filter {
            !it.title.contains("Yōon", true) && !it.title.contains("Gabungan", true)
        }
        val mainFlat = ResourceLoader.flatItems(mainGroups)
        val counts = kana.counts.first()
        val threshold = ceil(mainFlat.size * 0.5).toInt()
        val masteredMain = KanaRepository.masteredCount(counts, mainFlat, isKatakana)
        deckFlat = if (masteredMain >= threshold) currentFlat else mainFlat

        if (deckFlat.isEmpty()) {
            _state.value = _state.value.copy(deckEmpty = true)
            return
        }

        val notMastered = deckFlat.filter { !KanaRepository.isMastered(counts, it.kana, isKatakana) }
        val mastered = deckFlat.filter { KanaRepository.isMastered(counts, it.kana, isKatakana) }
        val result = ArrayList(notMastered.shuffled())
        if (result.size < sessionSize) result += mastered.shuffled().take(sessionSize - result.size)
        deck = result.take(sessionSize)

        currentIndex = 0; sessionCorrect = 0; selectedAnswer = null; isAnswered = false; finished = false
        question = deck.firstOrNull()?.let { makeQuestion(it) }
        push(counts)
    }

    private fun makeQuestion(card: KanaItem): FlashQuestion {
        val correct = card.romaji
        val wrongPool = deckFlat.map { it.romaji }.toSet() - correct
        val distractors = wrongPool.shuffled().take(3)
        val choices = (distractors + correct).shuffled()
        return FlashQuestion(card.kana, choices, correct)
    }

    fun handleAnswer(answer: String) {
        if (isAnswered) return
        val q = question ?: return
        selectedAnswer = answer
        isAnswered = true
        viewModelScope.launch {
            if (answer == q.correctAnswer) {
                kana.addCorrect(q.cardKana, isKatakana)
                sessionCorrect++
            } else {
                kana.addWrong(q.cardKana, isKatakana)
            }
            push(kana.counts.first())
        }
    }

    fun nextCard() {
        if (currentIndex + 1 >= deck.size) {
            finished = true
        } else {
            currentIndex++
            selectedAnswer = null
            isAnswered = false
            question = makeQuestion(deck[currentIndex])
        }
        viewModelScope.launch { push(kana.counts.first()) }
    }

    val isLastCard: Boolean get() = currentIndex + 1 >= deck.size

    private fun push(counts: Map<Pair<String, String>, Int>) {
        _state.value = KanaFlashcardUiState(
            isKatakana = isKatakana,
            deckEmpty = deck.isEmpty() && deckFlat.isEmpty(),
            finished = finished,
            currentIndex = currentIndex,
            deckSize = deck.size,
            sessionCorrect = sessionCorrect,
            question = question,
            selectedAnswer = selectedAnswer,
            isAnswered = isAnswered,
            masteredCount = KanaRepository.masteredCount(counts, progressFlat, isKatakana),
            totalCount = progressFlat.size,
        )
    }
}
