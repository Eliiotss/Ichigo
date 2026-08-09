package com.ichigo.app.ui.browse

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.model.grammarLevels
import com.ichigo.app.data.model.kanjiLevels
import com.ichigo.app.data.model.vocabularyLevels
import com.ichigo.app.data.repository.ContentRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class SearchType { KANJI, VOCAB, GRAMMAR }

data class SearchResult(
    val type: SearchType,
    val levelId: String,
    val jsonFile: String,
    val itemId: String,
    val title: String,
    val subtitle: String,
    // All matchable text (kanji, furigana/reading, katakana on'yomi, romaji, arti…).
    val searchKey: String,
)

/**
 * Loads every unlocked level's Kanji, Vocabulary and Grammar once into a flat
 * index, then filters it by a debounced query — a single search across the whole
 * app instead of the per-level list search.
 */
@OptIn(FlowPreview::class)
@HiltViewModel
class GlobalSearchViewModel @Inject constructor(
    private val content: ContentRepository,
) : ViewModel() {

    private val index = MutableStateFlow<List<SearchResult>>(emptyList())
    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()
    val searchText = MutableStateFlow("")

    val results: StateFlow<List<SearchResult>> =
        combine(index, searchText.debounce(200)) { list, query ->
            val q = query.trim()
            if (q.isEmpty()) emptyList()
            else list.filter { it.searchKey.contains(q, ignoreCase = true) }.take(80)
        }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    init {
        viewModelScope.launch {
            val all = ArrayList<SearchResult>()
            for (lvl in kanjiLevels.filterNot { it.isLocked }) {
                runCatching { content.loadKanji(lvl.jsonFile) }.getOrDefault(emptyList()).forEach { k ->
                    // kanji + on'yomi (katakana) + kun'yomi + romaji + arti + contoh (kata/furigana/arti)
                    val key = (listOf(k.kanji, k.onyomi, k.kunyomi, k.romaji, k.meaning) +
                        k.examples.flatMap { listOf(it.word, it.reading, it.romaji, it.meaning) }).joinToString(" ")
                    all += SearchResult(SearchType.KANJI, lvl.id, lvl.jsonFile, k.id, k.kanji, "${k.romaji} — ${k.meaning}", key)
                }
            }
            for (lvl in vocabularyLevels.filterNot { it.isLocked }) {
                runCatching { content.loadVocab(lvl.jsonFile) }.getOrDefault(emptyList()).forEach { v ->
                    val key = listOf(v.kanji, v.hiragana, v.arti, v.jenisKata).joinToString(" ")
                    all += SearchResult(SearchType.VOCAB, lvl.id, lvl.jsonFile, v.id, v.kanji.ifEmpty { v.hiragana }, "${v.hiragana} — ${v.arti}", key)
                }
            }
            for (lvl in grammarLevels.filterNot { it.isLocked }) {
                runCatching { content.loadGrammar(lvl.jsonFile) }.getOrDefault(emptyList()).forEach { g ->
                    val key = (listOf(g.pattern, g.romaji, g.meaning, g.explanation) + g.tags).joinToString(" ")
                    all += SearchResult(SearchType.GRAMMAR, lvl.id, lvl.jsonFile, g.id, g.pattern, "${g.romaji} — ${g.meaning}", key)
                }
            }
            index.value = all
            _loading.value = false
        }
    }

    fun setSearch(value: String) { searchText.value = value }
}
