package com.ichigo.app.data.repository

import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.KanaGroup
import com.ichigo.app.data.model.KanjiItem
import com.ichigo.app.data.model.VocabularyItem
import com.ichigo.app.data.resource.ResourceLoader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Read-only access to the bundled datasets, the Kotlin counterpart of the
 * `KanjiLoader` / `VocabularyLoader` / `GrammarLoader` / `KanaLoader` calls that
 * the SwiftUI browse screens make. Decoding runs off the main thread, matching
 * the `Task.detached(priority: .userInitiated)` loads in Swift.
 */
@Singleton
class ContentRepository @Inject constructor(
    private val loader: ResourceLoader,
) {
    suspend fun loadKanji(jsonFile: String): List<KanjiItem> =
        withContext(Dispatchers.IO) { loader.loadKanji(jsonFile) }

    suspend fun loadVocab(jsonFile: String): List<VocabularyItem> =
        withContext(Dispatchers.IO) { loader.loadVocab(jsonFile) }

    suspend fun loadGrammar(jsonFile: String): List<GrammarItem> =
        withContext(Dispatchers.IO) { loader.loadGrammar(jsonFile) }

    /** Loads Hiragana.json and returns all kana groups (both scripts mixed). */
    suspend fun loadKanaGroups(): List<KanaGroup> =
        withContext(Dispatchers.IO) { loader.loadKanaGroups("Hiragana") }

    /** Pre-warms the N5 datasets so the first screen open is instant (RootView splash). */
    suspend fun preloadCore() = withContext(Dispatchers.IO) {
        runCatching { loader.loadKanji("KanjiN5") }
        runCatching { loader.loadVocab("VocabN5") }
        runCatching { loader.loadGrammar("GrammarN5") }
        runCatching { loader.loadKanaGroups("Hiragana") }
    }
}
