package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.data.flashcard.FlashcardLoadState
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.grammarLevels
import com.ichigo.app.ui.components.EmptyState
import com.ichigo.app.ui.components.ErrorState
import com.ichigo.app.ui.components.ScreenHeader
import com.ichigo.app.ui.components.SearchField
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** Port of `GrammarView` — level picker. */
@Composable
fun GrammarLevelScreen(onBack: () -> Unit, onOpen: (ContentLevel) -> Unit) {
    LargeScreen(title = "Grammar", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            grammarLevels.forEach { level ->
                if (level.isLocked) LockedLevelCard(level) else UnlockedLevelCard(level) { onOpen(level) }
            }
        }
    }
}

/** Port of `GrammarListView` — search + pattern cards. */
@Composable
fun GrammarListScreen(onBack: () -> Unit, onOpenItem: (String) -> Unit, viewModel: GrammarListViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val loadState by viewModel.loadState.collectAsStateWithLifecycle()
    val filtered by viewModel.filtered.collectAsStateWithLifecycle()
    val search by viewModel.searchText.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Grammar", onBack)
        when (val s = loadState) {
            FlashcardLoadState.Loading, FlashcardLoadState.Idle -> CenterLoading("Memuat tata bahasa...")
            is FlashcardLoadState.Failed -> ErrorState(s.message, Modifier.fillMaxSize())
            FlashcardLoadState.Empty -> EmptyState("Belum tersedia", "Konten level ini belum tersedia.", modifier = Modifier.fillMaxSize())
            else -> {
                Spacer(Modifier.height(14.dp))
                SearchField(search, viewModel::setSearch, "Cari pola tata bahasa", Modifier.padding(horizontal = 20.dp))
                if (filtered.isEmpty()) {
                    Text("Tidak ditemukan", style = rounded(15, Wt.Medium), color = c.secondaryText, modifier = Modifier.fillMaxWidth().padding(top = 60.dp), textAlign = TextAlign.Center)
                } else {
                    LazyColumn(
                        Modifier.fillMaxSize(),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(20.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(filtered.size) { i -> GrammarListCard(filtered[i], viewModel.levelId) { onOpenItem(filtered[i].id) } }
                    }
                }
            }
        }
    }
}

@Composable
private fun GrammarListCard(item: GrammarItem, levelId: String, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).clickable(onClick = onClick).padding(18.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                "JLPT $levelId",
                style = rounded(11, Wt.Bold),
                color = IchigoPalette.Accent,
                modifier = Modifier.clip(RoundedCornerShape(50)).background(IchigoPalette.Accent.copy(alpha = 0.12f)).padding(horizontal = 10.dp, vertical = 5.dp),
            )
            Spacer(Modifier.weight(1f))
            if (item.treeCategory.isNotEmpty()) Text(item.treeCategory, style = rounded(12, Wt.Medium), color = c.secondaryText, maxLines = 1)
        }
        Text(item.pattern, style = rounded(26, Wt.Bold), color = c.primaryText, modifier = Modifier.padding(top = 14.dp))
        if (item.romaji.isNotEmpty()) Text(item.romaji, style = rounded(13), color = c.secondaryText, modifier = Modifier.padding(top = 3.dp))
        Text(item.meaning, style = rounded(15, Wt.Bold), color = IchigoPalette.Accent, modifier = Modifier.padding(top = 10.dp))
    }
}

/** Port of `GrammarDetailView`. */
@Composable
fun GrammarDetailScreen(onBack: () -> Unit, viewModel: GrammarDetailViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val item by viewModel.item.collectAsStateWithLifecycle()
    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Detail Grammar", onBack)
        item?.let { GrammarDetailContent(it) }
    }
}
