package com.ichigo.app.ui.browse

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.flashcard.FlashcardLoadState
import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.KanjiItem
import com.ichigo.app.data.model.VocabularyItem
import com.ichigo.app.data.repository.ContentRepository
import com.ichigo.app.ui.navigation.Routes
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Port of `KanjiListView`'s state: async load, 250 ms-debounced search across
 * kanji/meaning/romaji/onyomi/kunyomi and example words/readings.
 */
@OptIn(FlowPreview::class)
@HiltViewModel
class KanjiListViewModel @Inject constructor(
    private val content: ContentRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    val levelId: String = handle[Routes.Arg.LEVEL_ID] ?: ""
    private val jsonFile: String = handle[Routes.Arg.JSON_FILE] ?: ""

    private val _loadState = MutableStateFlow<FlashcardLoadState>(FlashcardLoadState.Loading)
    val loadState: StateFlow<FlashcardLoadState> = _loadState.asStateFlow()

    private val items = MutableStateFlow<List<KanjiItem>>(emptyList())
    val searchText = MutableStateFlow("")

    val filtered: StateFlow<List<KanjiItem>> =
        combine(items, searchText.debounce(250)) { list, query ->
            val q = query.trim()
            if (q.isEmpty()) list
            else list.filter { item ->
                item.kanji.contains(q) ||
                    item.meaning.contains(q, true) ||
                    item.romaji.contains(q, true) ||
                    item.onyomi.contains(q, true) ||
                    item.kunyomi.contains(q, true) ||
                    item.examples.any {
                        it.word.contains(q) || it.reading.contains(q) ||
                            it.romaji.contains(q, true) || it.meaning.contains(q, true)
                    }
            }
        }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    init {
        viewModelScope.launch {
            runCatching { content.loadKanji(jsonFile) }
                .onSuccess {
                    items.value = it
                    _loadState.value = if (it.isEmpty()) FlashcardLoadState.Empty else FlashcardLoadState.Loaded
                }
                .onFailure { _loadState.value = FlashcardLoadState.Failed(it.message ?: "Gagal memuat") }
        }
    }

    fun setSearch(value: String) { searchText.value = value }
}

/**
 * Port of `VocabularyListView`: load + search + a jenisKata filter chip row.
 */
@OptIn(FlowPreview::class)
@HiltViewModel
class VocabListViewModel @Inject constructor(
    private val content: ContentRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    val levelId: String = handle[Routes.Arg.LEVEL_ID] ?: ""
    private val jsonFile: String = handle[Routes.Arg.JSON_FILE] ?: ""

    private val _loadState = MutableStateFlow<FlashcardLoadState>(FlashcardLoadState.Loading)
    val loadState: StateFlow<FlashcardLoadState> = _loadState.asStateFlow()

    private val items = MutableStateFlow<List<VocabularyItem>>(emptyList())
    val searchText = MutableStateFlow("")
    val selectedFilter = MutableStateFlow("Semua")

    /** ["Semua"] + distinct word types in first-seen order (Swift `availableFilters`). */
    val availableFilters: StateFlow<List<String>> = items.map { list ->
        val ordered = arrayListOf("Semua")
        val seen = HashSet<String>()
        for (w in list) if (seen.add(w.jenisKata)) ordered.add(w.jenisKata)
        ordered.toList()
    }.stateIn(viewModelScope, SharingStarted.Eagerly, listOf("Semua"))

    val filtered: StateFlow<List<VocabularyItem>> =
        combine(items, searchText.debounce(250), selectedFilter) { list, query, filter ->
            var result = list
            if (filter != "Semua") result = result.filter { it.jenisKata == filter }
            val q = query.trim()
            if (q.isEmpty()) result
            else result.filter {
                it.kanji.contains(q) || it.hiragana.contains(q) ||
                    it.arti.contains(q, true) || it.jenisKata.contains(q, true)
            }
        }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    init {
        viewModelScope.launch {
            runCatching { content.loadVocab(jsonFile) }
                .onSuccess {
                    items.value = it
                    _loadState.value = if (it.isEmpty()) FlashcardLoadState.Empty else FlashcardLoadState.Loaded
                }
                .onFailure { _loadState.value = FlashcardLoadState.Failed(it.message ?: "Gagal memuat") }
        }
    }

    fun setSearch(value: String) { searchText.value = value }
    fun setFilter(value: String) { selectedFilter.value = value }
}

/**
 * Port of `GrammarListView`: load + search across pattern/romaji/meaning/
 * category/explanation/tags.
 */
@OptIn(FlowPreview::class)
@HiltViewModel
class GrammarListViewModel @Inject constructor(
    private val content: ContentRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    val levelId: String = handle[Routes.Arg.LEVEL_ID] ?: ""
    private val jsonFile: String = handle[Routes.Arg.JSON_FILE] ?: ""

    private val _loadState = MutableStateFlow<FlashcardLoadState>(FlashcardLoadState.Loading)
    val loadState: StateFlow<FlashcardLoadState> = _loadState.asStateFlow()

    private val items = MutableStateFlow<List<GrammarItem>>(emptyList())
    val searchText = MutableStateFlow("")

    val filtered: StateFlow<List<GrammarItem>> =
        combine(items, searchText.debounce(250)) { list, query ->
            val q = query.trim()
            if (q.isEmpty()) list
            else list.filter { item ->
                item.pattern.contains(q) ||
                    item.romaji.contains(q, true) ||
                    item.meaning.contains(q, true) ||
                    item.treeCategory.contains(q, true) ||
                    item.explanation.contains(q, true) ||
                    item.tags.any { it.contains(q, true) }
            }
        }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    init {
        viewModelScope.launch {
            runCatching { content.loadGrammar(jsonFile) }
                .onSuccess {
                    items.value = it
                    _loadState.value = if (it.isEmpty()) FlashcardLoadState.Empty else FlashcardLoadState.Loaded
                }
                .onFailure { _loadState.value = FlashcardLoadState.Failed(it.message ?: "Gagal memuat") }
        }
    }

    fun setSearch(value: String) { searchText.value = value }
}

/** Loads a single kanji by id for the detail screen (list is cached). */
@HiltViewModel
class KanjiDetailViewModel @Inject constructor(
    content: ContentRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    val levelId: String = handle[Routes.Arg.LEVEL_ID] ?: ""
    private val jsonFile: String = handle[Routes.Arg.JSON_FILE] ?: ""
    private val itemId: String = handle[Routes.Arg.ITEM_ID] ?: ""

    private val _item = MutableStateFlow<KanjiItem?>(null)
    val item: StateFlow<KanjiItem?> = _item.asStateFlow()

    init {
        viewModelScope.launch {
            _item.value = runCatching { content.loadKanji(jsonFile) }.getOrDefault(emptyList())
                .firstOrNull { it.id == itemId }
        }
    }
}

/** Loads a single grammar pattern by id for the detail screen. */
@HiltViewModel
class GrammarDetailViewModel @Inject constructor(
    content: ContentRepository,
    handle: SavedStateHandle,
) : ViewModel() {
    private val jsonFile: String = handle[Routes.Arg.JSON_FILE] ?: ""
    private val itemId: String = handle[Routes.Arg.ITEM_ID] ?: ""

    private val _item = MutableStateFlow<GrammarItem?>(null)
    val item: StateFlow<GrammarItem?> = _item.asStateFlow()

    init {
        viewModelScope.launch {
            _item.value = runCatching { content.loadGrammar(jsonFile) }.getOrDefault(emptyList())
                .firstOrNull { it.id == itemId }
        }
    }
}
