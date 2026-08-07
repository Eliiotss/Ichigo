package com.ichigo.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.model.AppAppearance
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

/**
 * Publishes the persisted appearance choice to the root theme, the equivalent of
 * `RootView`'s `@AppStorage(AppAppearance.storageKey)`.
 */
@HiltViewModel
class AppearanceViewModel @Inject constructor(
    prefs: AppPreferences,
) : ViewModel() {
    val appearance: StateFlow<AppAppearance> = prefs.appearance.stateIn(
        viewModelScope, SharingStarted.Eagerly, AppAppearance.SYSTEM,
    )
}
