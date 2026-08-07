package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.data.flashcard.FlashcardLoadState
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.VocabularyItem
import com.ichigo.app.data.model.vocabularyLevels
import com.ichigo.app.ui.components.EmptyState
import com.ichigo.app.ui.components.ErrorState
import com.ichigo.app.ui.components.FilterChipRow
import com.ichigo.app.ui.components.ScreenHeader
import com.ichigo.app.ui.components.SearchField
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** Port of `VocabularyView` — level picker. */
@Composable
fun VocabLevelScreen(onBack: () -> Unit, onOpen: (ContentLevel) -> Unit) {
    LargeScreen(title = "Vocabulary", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            vocabularyLevels.forEach { level ->
                if (level.isLocked) LockedLevelCard(level) else UnlockedLevelCard(level) { onOpen(level) }
            }
        }
    }
}

/** Port of `VocabularyListView` — search + jenisKata filter + inline cards. */
@Composable
fun VocabListScreen(onBack: () -> Unit, viewModel: VocabListViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val loadState by viewModel.loadState.collectAsStateWithLifecycle()
    val filtered by viewModel.filtered.collectAsStateWithLifecycle()
    val search by viewModel.searchText.collectAsStateWithLifecycle()
    val filters by viewModel.availableFilters.collectAsStateWithLifecycle()
    val selected by viewModel.selectedFilter.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("JLPT ${viewModel.levelId} Vocabulary", onBack)
        when (val s = loadState) {
            FlashcardLoadState.Loading, FlashcardLoadState.Idle -> CenterLoading("Memuat kosakata ${viewModel.levelId}...")
            is FlashcardLoadState.Failed -> ErrorState(s.message, Modifier.fillMaxSize())
            FlashcardLoadState.Empty -> EmptyState("Belum tersedia", "Konten level ini belum tersedia.", modifier = Modifier.fillMaxSize())
            else -> {
                Spacer(Modifier.height(14.dp))
                SearchField(search, viewModel::setSearch, "Cari kosakata", Modifier.padding(horizontal = 20.dp))
                Spacer(Modifier.height(12.dp))
                FilterChipRow(filters, selected, viewModel::setFilter)
                if (filtered.isEmpty()) {
                    Text("Tidak ditemukan", style = rounded(15, Wt.Medium), color = c.secondaryText, modifier = Modifier.fillMaxWidth().padding(top = 60.dp), textAlign = TextAlign.Center)
                } else {
                    LazyColumn(
                        Modifier.fillMaxSize(),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(20.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(filtered.size) { i -> VocabInlineCard(filtered[i], viewModel.levelId) }
                    }
                }
            }
        }
    }
}

@Composable
private fun VocabInlineCard(item: VocabularyItem, levelId: String) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "JLPT $levelId",
                style = rounded(11, Wt.Bold),
                color = Color.White,
                modifier = Modifier.clip(RoundedCornerShape(50)).background(IchigoPalette.Accent).padding(horizontal = 10.dp, vertical = 5.dp),
            )
            Spacer(Modifier.weight(1f))
            SpeakChip(item.kanji, size = 38)
        }
        Text(item.kanji, style = rounded(34, Wt.Bold), color = c.primaryText)
        Text(item.hiragana, style = rounded(14, Wt.Medium), color = c.secondaryText)
        Text(item.jenisKata, style = rounded(13, Wt.Bold), color = IchigoPalette.Accent)
        Text(item.arti, style = rounded(17, Wt.Medium), color = c.primaryText)
    }
}
