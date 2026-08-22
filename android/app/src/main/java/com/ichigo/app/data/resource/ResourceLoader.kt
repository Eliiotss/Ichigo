package com.ichigo.app.data.resource

import android.content.Context
import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.KanaGroup
import com.ichigo.app.data.model.KanaGroupJSON
import com.ichigo.app.data.model.KanaItem
import com.ichigo.app.data.model.KanjiItem
import com.ichigo.app.data.model.VocabularyItem
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Port of `JSONResourceCache` + `ResourceLoader` + `KanaLoader`.
 *
 * Every dataset is a JSON array of `@Serializable` values loaded from the app's
 * `assets/data/` folder (the Android equivalent of the bundled `Resources`
 * directory) and cached in-memory so repeated reads are free — the same contract
 * as the iOS `JSONResourceCache`.
 *
 * The [json] instance mirrors Swift's forgiving decode:
 *  - `ignoreUnknownKeys` → unknown JSON keys are skipped (like `CodingKeys`).
 *  - `coerceInputValues`  → a present-but-null value falls back to the property
 *    default, matching Swift's `decodeIfPresent(...) ?? default`.
 */
@Singleton
class ResourceLoader @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        isLenient = true
    }

    private val dataCache = ConcurrentHashMap<String, List<Any>>()

    private fun readText(filename: String): String =
        context.assets.open("data/$filename.json").bufferedReader().use { it.readText() }

    /** Decodes a bundled dataset, propagating the reason on failure. */
    @Suppress("UNCHECKED_CAST")
    fun <T> decodeList(filename: String, serializer: KSerializer<T>): List<T> {
        dataCache[filename]?.let { return it as List<T> }
        val text = readText(filename)
        val list = json.decodeFromString(ListSerializer(serializer), text)
        dataCache[filename] = list as List<Any>
        return list
    }

    /** Decodes a bundled dataset, yielding an empty list when it cannot be read. */
    fun <T> decodeListOrEmpty(filename: String, serializer: KSerializer<T>): List<T> =
        runCatching { decodeList(filename, serializer) }.getOrDefault(emptyList())

    // Typed conveniences, mirroring KanjiLoader/VocabularyLoader/GrammarLoader.
    fun loadKanji(filename: String): List<KanjiItem> = decodeList(filename, KanjiItem.serializer())
    fun loadVocab(filename: String): List<VocabularyItem> = decodeList(filename, VocabularyItem.serializer())
    fun loadGrammar(filename: String): List<GrammarItem> = decodeList(filename, GrammarItem.serializer())

    fun loadKanjiOrEmpty(filename: String): List<KanjiItem> = decodeListOrEmpty(filename, KanjiItem.serializer())
    fun loadVocabOrEmpty(filename: String): List<VocabularyItem> = decodeListOrEmpty(filename, VocabularyItem.serializer())
    fun loadGrammarOrEmpty(filename: String): List<GrammarItem> = decodeListOrEmpty(filename, GrammarItem.serializer())

    /**
     * Loads kana groups, converting the JSON shape into the runtime [KanaGroup]
     * grid exactly like Swift's `KanaLoader.load`. Never throws (matches
     * `loadArrayOrEmpty`) since the kana screen simply shows nothing on failure.
     */
    fun loadKanaGroups(filename: String = "Hiragana"): List<KanaGroup> =
        decodeListOrEmpty(filename, KanaGroupJSON.serializer()).map { group ->
            KanaGroup(
                title = group.title,
                subtitle = group.subtitle,
                items = group.rows.map { row -> row.map { cell -> cell?.let { KanaItem(it.kana, it.romaji) } } },
                columns = group.columns,
            )
        }

    companion object {
        /** Flattens the grid into a plain list of cells (Swift `KanaLoader.flatItems`). */
        fun flatItems(groups: List<KanaGroup>): List<KanaItem> =
            groups.flatMap { g -> g.items.flatMap { row -> row.filterNotNull() } }
    }
}
