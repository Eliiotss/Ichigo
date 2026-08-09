package com.ichigo.app.ui.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/**
 * The Home "Lainnya" screen: two columns for the exam tracks — JLPT and JFT.
 * Each opens its own section (placeholder for now).
 */
@Composable
fun LainnyaScreen(onBack: () -> Unit, onOpen: (String) -> Unit) {
    LargeScreen(title = "Lainnya", onBack = onBack) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 18.dp).padding(top = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            ExamCategoryCard(
                title = "JLPT",
                subtitle = "Japanese-Language Proficiency Test",
                icon = Icons.AutoMirrored.Filled.MenuBook,
                gradient = IchigoPalette.tileGradient("kanji"),
                modifier = Modifier.weight(1f),
            ) { onOpen("JLPT") }
            ExamCategoryCard(
                title = "JFT",
                subtitle = "Japan Foundation Test (JFT-Basic)",
                icon = Icons.Filled.School,
                gradient = IchigoPalette.tileGradient("flashcard"),
                modifier = Modifier.weight(1f),
            ) { onOpen("JFT") }
        }
    }
}

@Composable
private fun ExamCategoryCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    gradient: List<Color>,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val c = IchigoTheme.colors
    Column(
        modifier
            .ichigoCard(c.surface, c.cardShadow)
            .clickable(onClick = onClick)
            .padding(16.dp),
    ) {
        Box(
            Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(Dimens.TileIconRadius))
                .background(Brush.linearGradient(gradient)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
        }
        Spacer(Modifier.height(12.dp))
        Text(title, style = rounded(18, Wt.Heavy), color = c.primaryText)
        Spacer(Modifier.height(2.dp))
        Text(subtitle, style = rounded(11, Wt.Semibold), color = c.secondaryText)
    }
}
