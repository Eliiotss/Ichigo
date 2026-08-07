package com.ichigo.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.model.AppAppearance
import com.ichigo.app.data.repository.AccountRepository
import com.ichigo.app.data.repository.FlashcardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val displayName: String = "user123",
    val email: String = "",
    val dailyTarget: Int = 20,
    val notifEnabled: Boolean = false,
    val notifHour: Int = 20,
    val isDark: Boolean = false,
    val linkedGoogleEmail: String? = null,
)

/**
 * Port of `SettingsView`'s bindings. The theme toggle writes an explicit
 * light/dark choice (Swift `isDarkBinding`); target/notif-hour are steppers;
 * reset clears local flashcard data. Google Drive sync shows the not-configured
 * state (no OAuth client bundled) — the same "belum disetel" state iOS shows
 * before a `GoogleOAuth.plist` is added.
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val prefs: AppPreferences,
    private val account: AccountRepository,
    private val flashcards: FlashcardRepository,
) : ViewModel() {

    // `isDark` reflects the effective scheme; the screen passes the system value
    // in when appearance == SYSTEM so the toggle mirrors the device until tapped.
    private val effectiveDark = MutableStateFlow(false)

    val state: StateFlow<SettingsUiState> = combine(
        combine(prefs.userName, prefs.userEmail, prefs.dailyTarget) { n, e, t -> Triple(n, e, t) },
        combine(prefs.notifEnabled, prefs.notifHour) { en, h -> en to h },
        prefs.googleEmail,
        effectiveDark,
    ) { profile, notif, google, dark ->
        SettingsUiState(
            displayName = profile.first,
            email = profile.second,
            dailyTarget = profile.third,
            notifEnabled = notif.first,
            notifHour = notif.second,
            isDark = dark,
            linkedGoogleEmail = google,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, SettingsUiState())

    /** Called by the screen with the effective scheme so the slide toggle matches. */
    fun syncEffectiveDark(systemDark: Boolean) {
        viewModelScope.launch {
            effectiveDark.value = when (prefs.appearance.first()) {
                AppAppearance.SYSTEM -> systemDark
                AppAppearance.LIGHT -> false
                AppAppearance.DARK -> true
            }
        }
    }

    fun setName(value: String) = launch { account.setDisplayName(value) }
    fun setEmail(value: String) = launch { account.setEmail(value) }
    fun incTarget() = launch { prefs.setDailyTarget(state.value.dailyTarget + 5) }
    fun decTarget() = launch { prefs.setDailyTarget(state.value.dailyTarget - 5) }
    fun setNotifEnabled(value: Boolean) = launch { prefs.setNotifEnabled(value) }
    fun incNotifHour() = launch { prefs.setNotifHour(state.value.notifHour + 1) }
    fun decNotifHour() = launch { prefs.setNotifHour(state.value.notifHour - 1) }

    /** Slide toggle → explicit light/dark, matching `isDarkBinding`. */
    fun setDark(dark: Boolean) = launch {
        prefs.setAppearance(if (dark) AppAppearance.DARK else AppAppearance.LIGHT)
        effectiveDark.value = dark
    }

    fun resetAll() = launch { flashcards.resetAll() }

    private fun launch(block: suspend () -> Unit) = viewModelScope.launch { block() }
}
