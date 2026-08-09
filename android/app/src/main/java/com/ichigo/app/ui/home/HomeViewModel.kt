package com.ichigo.app.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.repository.AccountRepository
import com.ichigo.app.data.repository.FlashcardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import java.util.Calendar
import javax.inject.Inject

/** Port of `TimeGreeting` — Indonesian greeting by hour. */
object TimeGreeting {
    fun text(hour: Int): String = when (hour) {
        in 5..10 -> "Selamat pagi"
        in 11..14 -> "Selamat siang"
        in 15..17 -> "Selamat sore"
        else -> "Selamat malam"
    }

    fun now(): String = text(Calendar.getInstance().get(Calendar.HOUR_OF_DAY))
}

data class HomeUiState(
    val greeting: String = "Okaeri",
    val displayName: String = "user123",
    val initials: String = "US",
    val studiedToday: Int = 0,
    val target: Int = 20,
    val due: Int = 0,
    val streak: Int = 0,
    val mastered: Int = 0,
)

/**
 * Port of `HomeView`'s state: the time greeting, the account name/initials, and
 * the hero progress numbers (studied/target, due, streak, mastered) — all from
 * the same repository helpers `ProfileView` uses, so the numbers agree.
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val flashcards: FlashcardRepository,
    private val prefs: AppPreferences,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    private val refreshTrigger = MutableStateFlow(0L)

    init {
        combine(
            combine(prefs.userName, prefs.dailyTarget, prefs.streak) { name, target, streak -> Triple(name, target, streak) },
            prefs.learnedGrammarIds,
            flashcards.progress,
            refreshTrigger,
        ) { (name, target, streak), learned, _, _ ->
            flashcards.ensureLoaded()
            HomeUiState(
                greeting = TimeGreeting.now(),
                displayName = name,
                initials = AccountRepository.initials(name),
                studiedToday = flashcards.studiedTodayTotal(),
                target = target,
                due = flashcards.dailyDueTotal(target),
                streak = streak,
                // Mastered = flashcards mastered by FSRS + grammar marked as learned (star).
                mastered = flashcards.masteredTotal + learned.size,
            )
        }.onEach { _state.value = it }.launchIn(viewModelScope)
    }

    /** Recompute on return to foreground (Swift `onChange(scenePhase)`). */
    fun onResume() {
        refreshTrigger.value = System.currentTimeMillis()
    }
}
