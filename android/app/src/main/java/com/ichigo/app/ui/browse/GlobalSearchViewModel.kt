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
            else list.filter { it.title.contains(q, ignoreCase = true) || it.subtitle.contains(q, ignoreCase = true) }.take(80)
        }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    init {
        viewModelScope.launch {
            val all = ArrayList<SearchResult>()
            for (lvl in kanjiLevels.filterNot { it.isLocked }) {
                runCatching { content.loadKanji(lvl.jsonFile) }.getOrDefault(emptyList()).forEach {
                    all += SearchResult(SearchType.KANJI, lvl.id, lvl.jsonFile, it.id, it.kanji, "${it.romaji} — ${it.meaning}")
                }
            }
            for (lvl in vocabularyLevels.filterNot { it.isLocked }) {
                runCatching { content.loadVocab(lvl.jsonFile) }.getOrDefault(emptyList()).forEach {
                    all += SearchResult(SearchType.VOCAB, lvl.id, lvl.jsonFile, it.id, it.kanji.ifEmpty { it.hiragana }, "${it.hiragana} — ${it.arti}")
                }
            }
            for (lvl in grammarLevels.filterNot { it.isLocked }) {
                runCatching { content.loadGrammar(lvl.jsonFile) }.getOrDefault(emptyList()).forEach {
                    all += SearchResult(SearchType.GRAMMAR, lvl.id, lvl.jsonFile, it.id, it.pattern, "${it.romaji} — ${it.meaning}")
                }
            }
            index.value = all
            _loading.value = false
        }
    }

    fun setSearch(value: String) { searchText.value = value }
}
