package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow

/** A round back button (used by large-title screens). */
@Composable
fun BackButton(onBack: () -> Unit) {
    val c = IchigoTheme.colors
    Box(
        Modifier
            .size(44.dp)
            .softShadow(c.cardShadow, 6.dp, 22.dp, offsetY = 2.dp)
            .clip(CircleShape)
            .background(c.surface)
            .clickable(onClick = onBack),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.ChevronLeft, contentDescription = "Kembali", tint = c.primaryText)
    }
}

/** Large-title screen (iOS `.navigationBarTitleDisplayMode(.large)`) with a back button. */
@Composable
fun LargeScreen(title: String, onBack: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize().background(c.page)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            BackButton(onBack)
            Spacer(Modifier.width(14.dp))
            Text(title, style = rounded(30, Wt.Heavy), color = c.primaryText)
        }
        Spacer(Modifier.size(8.dp))
        content()
    }
}

/** Standard content-level card (Swift `VocabularyUnlockedCard` / `GrammarLevelCard`). */
@Composable
fun UnlockedLevelCard(level: ContentLevel, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Row(
        Modifier
            .fillMaxWidth()
            .ichigoCard(c.surface, c.cardShadow)
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LevelChip(level.id, level.bgColor, level.color)
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(level.name, style = rounded(17, Wt.Bold), color = c.primaryText, modifier = Modifier.weight(1f))
                Icon(Icons.Filled.ChevronRight, null, tint = c.secondaryText, modifier = Modifier.size(18.dp))
            }
            Spacer(Modifier.size(5.dp))
            Text(level.description, style = rounded(13), color = c.secondaryText)
        }
    }
}

/** Locked level card. */
@Composable
fun LockedLevelCard(level: ContentLevel) {
    val c = IchigoTheme.colors
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(c.surface.copy(alpha = 0.5f))
            .border(1.dp, Color.Gray.copy(alpha = 0.08f), RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LevelChip(level.id, Color.Gray.copy(alpha = 0.1f), c.secondaryText)
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(level.name, style = rounded(17, Wt.Bold), color = c.secondaryText, modifier = Modifier.weight(1f))
                Icon(Icons.Filled.Lock, null, tint = c.secondaryText, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(4.dp))
                Text("Terkunci", style = rounded(11, Wt.Semibold), color = c.secondaryText)
            }
            Spacer(Modifier.size(5.dp))
            Text(level.description, style = rounded(13), color = c.secondaryText.copy(alpha = 0.6f))
        }
    }
}

@Composable
fun LevelChip(id: String, bg: Color, fg: Color) {
    Box(
        Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)).background(bg),
        contentAlignment = Alignment.Center,
    ) {
        Text(id, style = rounded(18, Wt.Black), color = fg)
    }
}

/** Port of `ComingSoonView` (Home "Lainnya"). */
@Composable
fun ComingSoonScreen(feature: String, onBack: () -> Unit) {
    val c = IchigoTheme.colors
    LargeScreen(title = feature, onBack = onBack) {
        Column(
            Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(Icons.Filled.Build, null, tint = c.secondaryText, modifier = Modifier.size(44.dp))
            Spacer(Modifier.size(14.dp))
            Text("$feature Segera Hadir", style = rounded(22, Wt.Heavy), color = c.primaryText)
            Spacer(Modifier.size(6.dp))
            Text("Fitur ini sedang dikembangkan.", style = rounded(14, Wt.Medium), color = c.secondaryText)
        }
    }
}
