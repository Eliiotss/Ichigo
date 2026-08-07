package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
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
import com.ichigo.app.data.model.KanjiExample
import com.ichigo.app.data.model.KanjiItem
import com.ichigo.app.data.model.kanjiLevels
import com.ichigo.app.ui.components.EmptyState
import com.ichigo.app.ui.components.ErrorState
import com.ichigo.app.ui.components.ScreenHeader
import com.ichigo.app.ui.components.SearchField
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.browse.KanjiListViewModel

/** Port of `KanjiView` — the JLPT level picker. */
@Composable
fun KanjiLevelScreen(onBack: () -> Unit, onOpen: (com.ichigo.app.data.model.ContentLevel) -> Unit) {
    LargeScreen(title = "Kanji", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            kanjiLevels.forEach { level ->
                if (level.isLocked) LockedLevelCard(level) else UnlockedLevelCard(level) { onOpen(level) }
            }
        }
    }
}

/** Port of `KanjiListView` — search + 2-column grid of kanji cards. */
@Composable
fun KanjiListScreen(onBack: () -> Unit, onOpenItem: (String) -> Unit, viewModel: KanjiListViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val loadState by viewModel.loadState.collectAsStateWithLifecycle()
    val filtered by viewModel.filtered.collectAsStateWithLifecycle()
    val search by viewModel.searchText.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("JLPT ${viewModel.levelId} Kanji", onBack)
        when (val s = loadState) {
            FlashcardLoadState.Loading, FlashcardLoadState.Idle -> CenterLoading("Memuat kanji ${viewModel.levelId}...")
            is FlashcardLoadState.Failed -> ErrorState(s.message, Modifier.fillMaxSize())
            FlashcardLoadState.Empty -> EmptyState("Belum tersedia", "Konten level ini belum tersedia.", modifier = Modifier.fillMaxSize())
            else -> {
                Spacer(Modifier.height(14.dp))
                SearchField(search, viewModel::setSearch, "Cari Kanji (contoh: 日)", Modifier.padding(horizontal = 20.dp))
                if (filtered.isEmpty()) {
                    Text("Tidak ditemukan", style = rounded(15), color = c.secondaryText, modifier = Modifier.fillMaxWidth().padding(top = 60.dp), textAlign = TextAlign.Center)
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(filtered.size) { i -> KanjiCard(filtered[i]) { onOpenItem(filtered[i].id) } }
                    }
                }
            }
        }
    }
}

@Composable
private fun KanjiCard(item: KanjiItem, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Column(
        Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow).clickable(onClick = onClick).padding(vertical = 18.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(item.kanji, style = rounded(54), color = c.primaryText)
        Text("${item.onyomi} / ${item.kunyomi}", style = rounded(10, Wt.Bold), color = IchigoPalette.Accent, maxLines = 1)
        Text(item.meaning, style = rounded(13, Wt.Semibold), color = c.primaryText, maxLines = 1)
    }
}

/** Port of `KanjiDetailView`. */
@Composable
fun KanjiDetailScreen(onBack: () -> Unit, viewModel: KanjiDetailViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val item by viewModel.item.collectAsStateWithLifecycle()
    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Detail Kanji", onBack)
        item?.let { KanjiDetailContent(it, viewModel.levelId) }
    }
}

@Composable
internal fun CenterLoading(text: String) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        CircularProgressIndicator(color = IchigoPalette.Accent)
        Spacer(Modifier.height(12.dp))
        Text(text, style = rounded(14), color = c.secondaryText)
    }
}

// Small speak button used in vocab cards / kanji examples (accent tinted circle).
@Composable
internal fun SpeakChip(text: String, size: Int = 30) {
    val speech = com.ichigo.app.util.LocalSpeech.current
    Box(
        Modifier.size(size.dp).clip(CircleShape).background(IchigoPalette.Accent.copy(alpha = 0.12f)).clickable { speech.speak(text) },
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.AutoMirrored.Filled.VolumeUp, contentDescription = "Dengarkan", tint = IchigoPalette.Accent, modifier = Modifier.size((size * 0.5).dp))
    }
}
