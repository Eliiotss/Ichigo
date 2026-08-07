package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.automirrored.filled.FormatListBulleted
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.FormatQuote
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.ichigo.app.data.model.GrammarExample
import com.ichigo.app.data.model.GrammarItem
import com.ichigo.app.data.model.KanjiExample
import com.ichigo.app.data.model.KanjiItem
import com.ichigo.app.ui.components.DetailHeroCard
import com.ichigo.app.ui.components.DetailSectionCard
import com.ichigo.app.ui.components.HeroBadge
import com.ichigo.app.ui.components.HeroPill
import com.ichigo.app.ui.components.HeroSpeakButton
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** Body of `KanjiDetailView` (hero + reading cards + examples). */
@Composable
fun KanjiDetailContent(item: KanjiItem, levelId: String) {
    val c = IchigoTheme.colors
    Column(
        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 4.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        DetailHeroCard {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                    HeroBadge("JLPT $levelId")
                    Spacer(Modifier.weight(1f))
                    HeroSpeakButton(item.kanji)
                }
                Text(item.kanji, style = rounded(96), color = Color.White, modifier = Modifier.padding(top = 10.dp))
                Text(item.romaji, style = rounded(30, Wt.Bold), color = Color.White, modifier = Modifier.padding(top = 10.dp))
                Text(item.meaning, style = rounded(15), color = Color.White.copy(alpha = 0.9f), textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp, bottom = 4.dp))
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            ReadingCard("ONYOMI", item.onyomi, Modifier.weight(1f))
            ReadingCard("KUNYOMI", item.kunyomi, Modifier.weight(1f))
        }
        if (item.examples.isNotEmpty()) {
            Text("Contoh Kata & Kalimat", style = rounded(18, Wt.Bold), color = c.primaryText)
            item.examples.forEach { KanjiExampleCard(it) }
        }
    }
}

@Composable
private fun ReadingCard(title: String, value: String, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(modifier.ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(16.dp)) {
        Text(title, style = rounded(10, Wt.Bold), color = c.secondaryText)
        Spacer(Modifier.size(8.dp))
        Text(value.ifEmpty { "—" }, style = rounded(17, Wt.Bold), color = IchigoPalette.Accent, maxLines = 2)
    }
}

@Composable
private fun KanjiExampleCard(example: KanjiExample) {
    val c = IchigoTheme.colors
    val displaySentence = example.sentenceFurigana?.takeIf { it.isNotEmpty() } ?: example.sentence?.takeIf { it.isNotEmpty() }
    Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Text(example.word, style = rounded(19, Wt.Bold), color = c.primaryText)
            Spacer(Modifier.width(8.dp))
            Text("（${example.reading}）", style = rounded(13), color = c.secondaryText, modifier = Modifier.weight(1f))
            SpeakChip(example.sentence ?: example.word)
        }
        Text("${example.romaji} — ${example.meaning}", style = rounded(13, Wt.Semibold), color = IchigoPalette.Accent)
        if (displaySentence != null) {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(c.softSurface).padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(displaySentence, style = rounded(15, Wt.Medium), color = c.primaryText)
                example.sentenceMeaning?.takeIf { it.isNotEmpty() }?.let {
                    Text(it, style = rounded(13), color = c.secondaryText)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------

/** Body of `GrammarDetailView` (hero + nuance/frequency + sections). */
@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
fun GrammarDetailContent(item: GrammarItem) {
    val c = IchigoTheme.colors
    val heroPills = buildList {
        if (item.level.isNotEmpty()) add(item.level)
        if (item.treeCategory.isNotEmpty()) add(item.treeCategory)
        addAll(item.tags)
    }
    Column(
        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 4.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        DetailHeroCard {
            Column(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                    HeroBadge("JLPT ${item.level}")
                    Spacer(Modifier.weight(1f))
                    if (item.structure.isNotEmpty()) HeroPill(item.structure)
                }
                Text(item.pattern, style = rounded(34, Wt.Bold), color = Color.White, modifier = Modifier.padding(top = 14.dp))
                if (item.romaji.isNotEmpty()) Text(item.romaji, style = rounded(14), color = Color.White.copy(alpha = 0.85f), modifier = Modifier.padding(top = 4.dp))
                Text(item.meaning, style = rounded(18, Wt.Bold), color = Color.White, modifier = Modifier.padding(top = 10.dp))
                if (heroPills.isNotEmpty()) {
                    FlowRow(Modifier.padding(top = 14.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        heroPills.forEach { HeroPill(it) }
                    }
                }
            }
        }
        if (item.nuance.isNotEmpty() || item.frequency.isNotEmpty()) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (item.nuance.isNotEmpty()) MiniInfoCard("NUANCE", item.nuance, c.primaryText, Modifier.weight(1f))
                if (item.frequency.isNotEmpty()) MiniInfoCard("FREQUENCY", item.frequency, IchigoPalette.Accent, Modifier.weight(1f))
            }
        }
        if (item.explanation.isNotEmpty()) {
            DetailSectionCard("Arti", Icons.AutoMirrored.Filled.Article) {
                Text(item.explanation, style = rounded(15), color = c.primaryText)
            }
        }
        if (item.usage.isNotEmpty()) {
            DetailSectionCard("Penggunaan", Icons.AutoMirrored.Filled.FormatListBulleted) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item.usage.forEach { point ->
                        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(c.softSurface).padding(12.dp), verticalAlignment = Alignment.Top) {
                            Box(Modifier.padding(top = 7.dp).size(7.dp).clip(CircleShape).background(IchigoPalette.Accent))
                            Spacer(Modifier.width(10.dp))
                            Text(point, style = rounded(14), color = c.primaryText)
                        }
                    }
                }
            }
        }
        if (item.commonMistakes.isNotEmpty()) {
            DetailSectionCard("Kesalahan Umum", Icons.Filled.Warning, tint = IchigoPalette.Danger) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item.commonMistakes.forEach { mistake ->
                        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(IchigoPalette.Danger.copy(alpha = if (c.isDark) 0.16f else 0.07f)).padding(12.dp), verticalAlignment = Alignment.Top) {
                            Icon(Icons.Filled.Cancel, null, tint = IchigoPalette.Danger, modifier = Modifier.size(14.dp).padding(top = 1.dp))
                            Spacer(Modifier.width(10.dp))
                            Text(mistake, style = rounded(14), color = c.primaryText)
                        }
                    }
                }
            }
        }
        if (item.examples.isNotEmpty()) {
            DetailSectionCard(
                "Contoh Kalimat",
                Icons.Filled.FormatQuote,
                trailing = {
                    Text("${item.examples.size} kalimat", style = rounded(11, Wt.Bold), color = IchigoPalette.Accent, modifier = Modifier.clip(RoundedCornerShape(50)).background(IchigoPalette.Accent.copy(alpha = 0.12f)).padding(horizontal = 10.dp, vertical = 5.dp))
                },
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item.examples.forEachIndexed { i, ex -> GrammarExampleCard(ex, i + 1) }
                }
            }
        }
    }
}

@Composable
private fun MiniInfoCard(title: String, value: String, valueColor: Color, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(modifier.ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Text(title, style = rounded(10, Wt.Bold), color = c.secondaryText)
        Text(value, style = rounded(15, Wt.Semibold), color = valueColor)
    }
}

@Composable
private fun GrammarExampleCard(example: GrammarExample, number: Int) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(c.softSurface).padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Box(Modifier.size(22.dp).clip(CircleShape).background(IchigoPalette.Accent), contentAlignment = Alignment.Center) {
                Text("$number", style = rounded(11, Wt.Bold), color = Color.White)
            }
            Spacer(Modifier.width(10.dp))
            Text(example.japanese, style = rounded(17, Wt.Semibold), color = c.primaryText)
        }
        if (example.romaji.isNotEmpty()) Text(example.romaji, style = rounded(13), color = c.secondaryText, modifier = Modifier.padding(start = 32.dp))
        if (example.translation.isNotEmpty()) Text(example.translation, style = rounded(14, Wt.Bold), color = c.primaryText, modifier = Modifier.padding(start = 32.dp))
    }
}
