package com.ichigo.app.util

import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.compose.runtime.staticCompositionLocalOf
import java.util.Locale

/**
 * Port of `AudioSpeechHelper` — Japanese text-to-speech for the vocab cards and
 * kanji examples. Uses Android [TextToSpeech] with the Japanese voice at a
 * slightly slower rate, matching the iOS `AVSpeechUtterance(rate: 0.42)` intent
 * of being clear for study. Provided app-wide via [LocalSpeech].
 */
class SpeechHelper(context: Context) {
    private var ready = false
    private val tts: TextToSpeech = TextToSpeech(context.applicationContext) { status ->
        if (status == TextToSpeech.SUCCESS) {
            tts.language = Locale.JAPANESE
            tts.setSpeechRate(0.9f)
            ready = true
        }
    }

    /** Speaks Japanese text, interrupting anything already playing. */
    fun speak(text: String) {
        if (!ready || text.isEmpty()) return
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "ichigo-tts")
    }

    fun shutdown() {
        runCatching { tts.stop(); tts.shutdown() }
    }
}

/** App-wide speech helper, set once at the Compose root. */
val LocalSpeech = staticCompositionLocalOf<SpeechHelper> {
    error("LocalSpeech not provided")
}
