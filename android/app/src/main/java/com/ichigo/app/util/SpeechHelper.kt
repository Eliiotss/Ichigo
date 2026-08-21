package com.ichigo.app.util

import android.speech.tts.TextToSpeech
import android.content.Context
import androidx.compose.runtime.staticCompositionLocalOf
import java.util.Locale

/**
 * Port of `AudioSpeechHelper` — Japanese text-to-speech for the vocab cards and
 * kanji examples. Uses Android [TextToSpeech] with the Japanese voice at a
 * slightly slower rate, matching the iOS `AVSpeechUtterance(rate: 0.42)` intent
 * of being clear for study. Provided app-wide via [LocalSpeech].
 */
class SpeechHelper(context: Context) {

    @Volatile private var ready = false
    private var configured = false

    // The engine is configured on first use, not inside the init callback: that
    // callback can be delivered before the constructor has finished assigning
    // this field, so touching it from there risks a NullPointerException.
    private var engine: TextToSpeech? = null

    init {
        engine = TextToSpeech(context.applicationContext) { status ->
            ready = status == TextToSpeech.SUCCESS
        }
    }

    /** Speaks Japanese text, interrupting anything already playing. */
    fun speak(text: String) {
        if (!ready || text.isEmpty()) return
        val tts = engine ?: return
        if (!configured) {
            tts.setLanguage(Locale.JAPANESE)
            tts.setSpeechRate(0.9f)
            configured = true
        }
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "ichigo-tts")
    }

    fun shutdown() {
        runCatching {
            engine?.stop()
            engine?.shutdown()
        }
        engine = null
        ready = false
        configured = false
    }
}

/** App-wide speech helper, set once at the Compose root. */
val LocalSpeech = staticCompositionLocalOf<SpeechHelper> {
    error("LocalSpeech not provided")
}
