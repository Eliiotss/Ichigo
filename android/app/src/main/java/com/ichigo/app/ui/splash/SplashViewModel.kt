package com.ichigo.app.ui.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.repository.ContentRepository
import com.ichigo.app.data.repository.FlashcardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Port of `AppLoadingState` (RootView.swift). Pre-warms the datasets and decks
 * behind the splash, advancing a real progress value and honouring a minimum
 * on-screen time so the splash never merely flickers on a fast device.
 */
@HiltViewModel
class SplashViewModel @Inject constructor(
    private val content: ContentRepository,
    private val flashcards: FlashcardRepository,
    private val prefs: AppPreferences,
) : ViewModel() {

    data class SplashState(
        val isReady: Boolean = false,
        val statusText: String = "Menyiapkan aplikasi…",
        val progress: Float = 0f,
    )

    private val _state = MutableStateFlow(SplashState())
    val state: StateFlow<SplashState> = _state.asStateFlow()

    private var started = false

    fun prepare() {
        if (started) return
        started = true
        viewModelScope.launch {
            prefs.registerFirstInstallIfNeeded(System.currentTimeMillis())
            val start = System.currentTimeMillis()

            _state.value = _state.value.copy(statusText = "Memuat kanji…")
            content.preloadCore()
            advance(0.5f)
            _state.value = _state.value.copy(statusText = "Menyiapkan deck…")
            flashcards.preloadAllDecks()
            advance(1f)

            _state.value = _state.value.copy(statusText = "Hampir selesai…")
            val elapsed = System.currentTimeMillis() - start
            if (elapsed < MIN_SPLASH_MS) delay(MIN_SPLASH_MS - elapsed)
            _state.value = _state.value.copy(isReady = true)
        }
    }

    private fun advance(value: Float) {
        _state.value = _state.value.copy(progress = value)
    }

    companion object {
        private const val MIN_SPLASH_MS = 650L
    }
}
