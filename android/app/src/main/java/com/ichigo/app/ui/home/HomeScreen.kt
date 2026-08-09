package com.ichigo.app.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Style
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.navigation.Routes
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow

private data class MenuItem(
    val id: String,
    val label: String,
    val sub: String,
    val icon: ImageVector,
    val route: String,
)

private val menuItems = listOf(
    MenuItem("huruf", "Huruf", "Kana", Icons.Filled.Translate, Routes.HIRAGANA),
    MenuItem("kanji", "Kanji", "Aksara", Icons.Filled.MenuBook, Routes.KANJI),
    MenuItem("flashcard", "Flashcard", "Review Cepat", Icons.Filled.Style, Routes.FLASHCARD),
    MenuItem("vocabulary", "Vocabulary", "Kosakata", Icons.AutoMirrored.Filled.MenuBook, Routes.VOCAB),
    MenuItem("grammar", "Grammar", "Tata Bahasa", Icons.AutoMirrored.Filled.Article, Routes.GRAMMAR),
    MenuItem("lainnya", "Lainnya", "Fitur Lain", Icons.Filled.GridView, Routes.LAINNYA),
)

/** Port of `HomeView`: greeting, blue hero progress card, and the menu grid. */
@Composable
fun HomeScreen(
    onOpenRoute: (String) -> Unit,
    onOpenProfile: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()
    val isTablet = LocalConfiguration.current.screenWidthDp > 600
    val columns = if (isTablet) 3 else 2

    LazyVerticalGrid(
        columns = GridCells.Fixed(columns),
        modifier = Modifier.fillMaxWidth().background(c.page),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            start = if (isTablet) 32.dp else 18.dp,
            end = if (isTablet) 32.dp else 18.dp,
            top = 8.dp,
            bottom = Dimens.ScreenBottomPadding,
        ),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item(span = { GridItemSpan(maxLineSpan) }) {
            GreetingHeader(state, onOpenProfile)
        }
        item(span = { GridItemSpan(maxLineSpan) }) {
            HeroCard(state)
        }
        item(span = { GridItemSpan(maxLineSpan) }) {
            Spacer(Modifier.height(4.dp))
        }
        items(menuItems.size) { index ->
            val item = menuItems[index]
            MenuCard(item) { onOpenRoute(item.route) }
        }
    }
}

@Composable
private fun GreetingHeader(state: HomeUiState, onOpenProfile: () -> Unit) {
    val c = IchigoTheme.colors
    Row(Modifier.fillMaxWidth().padding(bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(
                "${state.greeting}, ${state.displayName}",
                style = rounded(26, Wt.Heavy),
                color = c.primaryText,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.width(12.dp))
        Box(
            Modifier
                .size(46.dp)
                .softShadow(IchigoPalette.Blue.copy(alpha = 0.35f), 8.dp, 23.dp, offsetY = 6.dp)
                .clip(CircleShape)
                .background(Brush.linearGradient(IchigoPalette.AccentGradient))
                .clickable(onClick = onOpenProfile),
            contentAlignment = Alignment.Center,
        ) {
            Text(state.initials, style = rounded(17, Wt.Heavy), color = Color.White)
        }
    }
}

@Composable
private fun HeroCard(state: HomeUiState) {
    val progress = if (state.target > 0) (state.studiedToday.toFloat() / state.target).coerceIn(0f, 1f) else 0f
    Box(
        Modifier
            .fillMaxWidth()
            .softShadow(IchigoPalette.Blue.copy(alpha = 0.35f), 16.dp, Dimens.HeroRadius, offsetY = 14.dp)
            .clip(RoundedCornerShape(Dimens.HeroRadius))
            .background(Brush.linearGradient(IchigoPalette.AccentGradient))
            .padding(20.dp),
    ) {
        Column {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("PROGRESS HARI INI", style = rounded(13, Wt.Heavy), color = Color.White.copy(alpha = 0.9f))
                Spacer(Modifier.weight(1f))
                Text("${state.studiedToday}/${state.target}", style = rounded(15, Wt.Heavy), color = Color.White)
            }
            Spacer(Modifier.height(14.dp))
            Box(
                Modifier.fillMaxWidth().height(9.dp).clip(RoundedCornerShape(50)).background(Color.White.copy(alpha = 0.28f)),
            ) {
                Box(Modifier.fillMaxWidth(progress).height(9.dp).clip(RoundedCornerShape(50)).background(Color.White))
            }
            Spacer(Modifier.height(14.dp))
            // IntrinsicSize.Min sizes the row to its content so the stat labels are
            // never clipped by the card edge (and the dividers match that height).
            Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                HeroStat("${state.due}", "Total kartu hari ini", showDivider = false, modifier = Modifier.weight(1f))
                HeroStat("🔥 ${state.streak}", "Streak", showDivider = true, modifier = Modifier.weight(1f))
                HeroStat("${state.mastered}", "Mastered", showDivider = true, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun HeroStat(value: String, label: String, showDivider: Boolean, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxHeight(), verticalAlignment = Alignment.CenterVertically) {
        if (showDivider) {
            Box(Modifier.width(1.dp).fillMaxHeight().background(Color.White.copy(alpha = 0.28f)))
            Spacer(Modifier.width(10.dp))
        }
        Column {
            Text(value, style = rounded(22, Wt.Heavy), color = Color.White, maxLines = 1)
            // Allow wrapping to 2 lines so long labels ("Total kartu hari ini") fit;
            // IntrinsicSize.Min on the parent row grows to accommodate them.
            Text(label, style = rounded(11, Wt.Bold), color = Color.White.copy(alpha = 0.85f), maxLines = 2)
        }
    }
}

@Composable
private fun MenuCard(item: MenuItem, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Column(
        Modifier
            .fillMaxWidth()
            .ichigoCard(c.surface, c.cardShadow)
            .clickable(onClick = onClick)
            .padding(16.dp),
    ) {
        Box(
            Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(Dimens.TileIconRadius))
                .background(Brush.linearGradient(IchigoPalette.tileGradient(item.id))),
            contentAlignment = Alignment.Center,
        ) {
            Icon(item.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
        }
        Spacer(Modifier.height(12.dp))
        Text(item.label, style = rounded(15, Wt.Heavy), color = c.primaryText)
        Text(item.sub, style = rounded(12, Wt.Semibold), color = c.secondaryText)
    }
}
