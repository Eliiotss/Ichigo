package com.ichigo.app.ui.hiragana

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.data.model.KanaGroup
import com.ichigo.app.data.model.KanaItem
import com.ichigo.app.data.repository.KanaRepository
import com.ichigo.app.ui.browse.BackButton
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** Port of `HiraganaView` — segmented kana chart with mastery bars + flashcard button. */
@Composable
fun HiraganaScreen(onBack: () -> Unit, onStartFlashcard: (Boolean) -> Unit, viewModel: HiraganaViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()
    val accent = if (state.isKatakana) IchigoPalette.Indigo else IchigoPalette.Blue

    Box(Modifier.fillMaxSize().background(c.page)) {
        Column(Modifier.fillMaxSize()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                BackButton(onBack)
                Spacer(Modifier.width(14.dp))
                Text("Huruf", style = rounded(30, Wt.Heavy), color = c.primaryText)
            }
            Spacer(Modifier.height(10.dp))
            Segmented(state.selectedTab, viewModel::setTab)

            if (state.isLoading) {
                Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    CircularProgressIndicator(color = accent)
                    Spacer(Modifier.height(10.dp))
                    Text("Memuat huruf...", style = rounded(14), color = c.secondaryText)
                }
            } else {
                LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 100.dp)) {
                    item {
                        ProgressCard(state.masteredCount, state.currentFlat.size, state.progressValue, state.isKatakana)
                    }
                    items(state.currentGroups.size) { i ->
                        KanaGroupSection(state.currentGroups[i], state.counts, state.isKatakana)
                    }
                }
            }
        }
        if (!state.isLoading) {
            Box(
                Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(horizontal = 16.dp, vertical = 20.dp)
                    .height(54.dp).clip(RoundedCornerShape(16.dp)).background(accent).clickable { onStartFlashcard(state.isKatakana) },
                contentAlignment = Alignment.Center,
            ) {
                Text("Flashcard ${if (state.isKatakana) "Katakana" else "Hiragana"}", style = rounded(16, Wt.Bold), color = Color.White)
            }
        }
    }
}

@Composable
private fun Segmented(selected: Int, onSelect: (Int) -> Unit) {
    val c = IchigoTheme.colors
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp).clip(RoundedCornerShape(10.dp)).background(c.track).padding(3.dp),
    ) {
        listOf("Hiragana", "Katakana").forEachIndexed { index, label ->
            val active = index == selected
            Box(
                Modifier.weight(1f).clip(RoundedCornerShape(8.dp)).background(if (active) c.surface else Color.Transparent).clickable { onSelect(index) }.padding(vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(label, style = rounded(14, if (active) Wt.Semibold else Wt.Medium), color = if (active) c.primaryText else c.secondaryText)
            }
        }
    }
}

@Composable
private fun ProgressCard(mastered: Int, total: Int, progress: Float, isKatakana: Boolean) {
    val c = IchigoTheme.colors
    val grad = if (isKatakana) listOf(IchigoPalette.Indigo, IchigoPalette.Navy) else listOf(IchigoPalette.BlueLight, IchigoPalette.Blue)
    Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp).fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Progres Hafalan", style = rounded(16, Wt.Bold), color = c.primaryText, modifier = Modifier.weight(1f))
            Text("$mastered dari $total huruf", style = rounded(13), color = c.secondaryText)
        }
        Spacer(Modifier.height(10.dp))
        Box(Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(50)).background(c.track)) {
            Box(Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(8.dp).clip(RoundedCornerShape(50)).background(Brush.horizontalGradient(grad)))
        }
    }
}

@Composable
private fun KanaGroupSection(group: KanaGroup, counts: Map<Pair<String, String>, Int>, isKatakana: Boolean) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().padding(top = 12.dp)) {
        Text(group.title, style = rounded(18, Wt.Bold), color = c.primaryText, modifier = Modifier.padding(horizontal = 16.dp))
        if (group.subtitle.isNotEmpty()) Text(group.subtitle, style = rounded(13), color = c.secondaryText, modifier = Modifier.padding(horizontal = 16.dp))
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            group.columns.forEach { col ->
                Text(col.uppercase(), style = rounded(10, Wt.Bold), color = c.secondaryText, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            }
        }
        Spacer(Modifier.height(4.dp))
        group.items.forEach { row ->
            Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                row.forEach { cell ->
                    if (cell != null) KanaCell(cell, counts, isKatakana, Modifier.weight(1f))
                    else Box(Modifier.weight(1f).height(74.dp))
                }
            }
            Spacer(Modifier.height(4.dp))
        }
    }
}

@Composable
private fun KanaCell(item: KanaItem, counts: Map<Pair<String, String>, Int>, isKatakana: Boolean, modifier: Modifier) {
    val c = IchigoTheme.colors
    val accent = if (isKatakana) IchigoPalette.Indigo else IchigoPalette.Blue
    val mastered = KanaRepository.isMastered(counts, item.kana, isKatakana)
    val bar = KanaRepository.barProgress(counts, item.kana, isKatakana).toFloat()
    Column(
        modifier
            .height(74.dp)
            .ichigoCard(c.surface, c.cardShadow, radius = 16.dp, shadowRadius = 6.dp, shadowY = 2.dp)
            .then(if (mastered) Modifier.border(1.5.dp, IchigoPalette.Success.copy(alpha = 0.55f), RoundedCornerShape(16.dp)) else Modifier)
            .padding(horizontal = 10.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(item.kana, style = rounded(26, Wt.Semibold), color = c.primaryText)
        Text(item.romaji.uppercase(), style = rounded(9, Wt.Bold), color = c.secondaryText)
        Spacer(Modifier.height(4.dp))
        Box(Modifier.fillMaxWidth().height(3.dp).clip(RoundedCornerShape(50)).background(c.track)) {
            Box(Modifier.fillMaxWidth(bar).height(3.dp).clip(RoundedCornerShape(50)).background(if (mastered) IchigoPalette.Success else accent))
        }
    }
}
