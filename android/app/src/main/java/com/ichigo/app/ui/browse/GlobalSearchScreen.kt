package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
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
import com.ichigo.app.ui.components.ScreenHeader
import com.ichigo.app.ui.components.SearchField
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** One search screen across every unlocked level and content type. */
@Composable
fun GlobalSearchScreen(
    onBack: () -> Unit,
    onOpenResult: (SearchResult) -> Unit,
    viewModel: GlobalSearchViewModel = hiltViewModel(),
) {
    val c = IchigoTheme.colors
    val results by viewModel.results.collectAsStateWithLifecycle()
    val loading by viewModel.loading.collectAsStateWithLifecycle()
    val query by viewModel.searchText.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Cari", onBack)
        Spacer(Modifier.height(14.dp))
        SearchField(query, viewModel::setSearch, "Cari kanji, kosakata, tata bahasa", Modifier.padding(horizontal = 20.dp))
        when {
            loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = IchigoPalette.Accent)
            }
            query.isBlank() -> Hint("Ketik untuk mencari di semua level sekaligus.")
            results.isEmpty() -> Hint("Tidak ditemukan.")
            else -> LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                items(results.size) { i -> ResultCard(results[i]) { onOpenResult(results[i]) } }
            }
        }
    }
}

@Composable
private fun Hint(text: String) {
    Text(
        text,
        style = rounded(15, Wt.Medium),
        color = IchigoTheme.colors.secondaryText,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth().padding(top = 60.dp, start = 30.dp, end = 30.dp),
    )
}

@Composable
private fun ResultCard(r: SearchResult, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    val (label, color) = when (r.type) {
        SearchType.KANJI -> "Kanji" to IchigoPalette.Indigo
        SearchType.VOCAB -> "Kosakata" to IchigoPalette.Teal
        SearchType.GRAMMAR -> "Tata Bahasa" to IchigoPalette.Violet
    }
    Row(
        Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).clickable(onClick = onClick).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(label, style = rounded(10, Wt.Bold), color = Color.White, modifier = Modifier.clip(RoundedCornerShape(50)).background(color).padding(horizontal = 8.dp, vertical = 3.dp))
                Spacer(Modifier.size(8.dp))
                Text("JLPT ${r.levelId}", style = rounded(11, Wt.Bold), color = c.secondaryText)
            }
            Spacer(Modifier.height(6.dp))
            Text(r.title, style = rounded(19, Wt.Bold), color = c.primaryText, maxLines = 1)
            if (r.subtitle.isNotBlank()) Text(r.subtitle, style = rounded(13, Wt.Medium), color = c.secondaryText, maxLines = 1)
        }
        Icon(Icons.Filled.ChevronRight, null, tint = c.secondaryText, modifier = Modifier.size(18.dp))
    }
}
