package com.ichigo.app.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.runtime.CompositionLocalProvider
import com.ichigo.app.ui.navigation.MainScaffold
import com.ichigo.app.ui.splash.SplashScreen
import com.ichigo.app.util.LocalSpeech
import com.ichigo.app.util.SpeechHelper

/**
 * Compose root. Mirrors `RootView`: the main tab UI sits underneath an in-app
 * splash that fades out once datasets/decks are pre-warmed. Also provides the
 * app-wide [SpeechHelper] to every screen.
 */
@Composable
fun IchigoApp() {
    val context = LocalContext.current
    val speech = remember { SpeechHelper(context.applicationContext) }
    DisposableEffect(Unit) { onDispose { speech.shutdown() } }

    CompositionLocalProvider(LocalSpeech provides speech) {
        var ready by rememberSaveable { mutableStateOf(false) }
        Box(Modifier.fillMaxSize()) {
            MainScaffold()
            AnimatedVisibility(visible = !ready, exit = fadeOut()) {
                SplashScreen(onReady = { ready = true })
            }
        }
    }
}
