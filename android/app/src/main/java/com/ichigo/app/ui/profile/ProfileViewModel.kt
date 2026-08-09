package com.ichigo.app.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.flashcard.FlashcardAnalyticsSummary
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.repository.AccountRepository
import com.ichigo.app.data.repository.FlashcardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

data class ProfileUiState(
    val displayName: String = "user123",
    val initials: String = "US",
    val studiedToday: Int = 0,
    val target: Int = 20,
    val due: Int = 0,
    val streak: Int = 0,
    val mastered: Int = 0,
    val summary: FlashcardAnalyticsSummary = FlashcardAnalyticsSummary(),
) {
    val targetProgress: Float get() = if (target > 0) minOf(studiedToday.toFloat() / target, 1f) else 0f
}

/** Port of `ProfileView`'s state — the same numbers as Home plus the answer summary. */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val flashcards: FlashcardRepository,
    prefs: AppPreferences,
) : ViewModel() {

    val state: StateFlow<ProfileUiState> = combine(
        combine(prefs.userName, prefs.dailyTarget, prefs.streak) { name, target, streak -> Triple(name, target, streak) },
        prefs.analytics,
        prefs.learnedGrammarIds,
        flashcards.progress,
    ) { (name, target, streak), summary, learned, _ ->
        flashcards.ensureLoaded()
        ProfileUiState(
            displayName = name,
            initials = AccountRepository.initials(name),
            studiedToday = flashcards.studiedTodayTotal(),
            target = target,
            due = flashcards.dailyDueTotal(target),
            streak = streak,
            // Mastered = flashcards mastered by FSRS + grammar marked as learned (star).
            mastered = flashcards.masteredTotal + learned.size,
            summary = summary,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, ProfileUiState())
}
