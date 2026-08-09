package com.ichigo.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Star
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import kotlin.math.roundToInt

/** Port of `ProfileView`. */
@Composable
fun ProfileScreen(viewModel: ProfileViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()

    LazyColumn(
        Modifier.fillMaxWidth().background(c.page),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = Dimens.ScreenBottomPadding),
    ) {
        item { Header(state.initials, state.displayName) }
        item {
            Column(Modifier.padding(horizontal = 18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Spacer(Modifier.height(14.dp))
                TargetCard(state.studiedToday, state.target, state.targetProgress)
                StatsGrid(state)
                AnswerSummary(state)
            }
        }
    }
}

@Composable
private fun Header(initials: String, name: String) {
    Box(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(bottomStart = 34.dp, bottomEnd = 34.dp))
            .background(Brush.linearGradient(listOf(IchigoPalette.BlueLight, IchigoPalette.Blue)))
            .padding(horizontal = 18.dp).padding(top = 20.dp, bottom = 30.dp),
    ) {
        // decorative circle
        Box(Modifier.align(Alignment.TopEnd).size(140.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.1f)))
        Column(Modifier.fillMaxWidth()) {
            Text("Profile", style = rounded(22, Wt.Heavy), color = Color.White)
            Spacer(Modifier.height(16.dp))
            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(
                    Modifier.size(88.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.22f)).border(3.dp, Color.White.copy(alpha = 0.6f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(initials, style = rounded(32, Wt.Heavy), color = Color.White)
                }
                Text(name, style = rounded(22, Wt.Heavy), color = Color.White, maxLines = 1)
                Text("JLPT Learner", style = rounded(12, Wt.Heavy), color = IchigoPalette.Blue, modifier = Modifier.clip(RoundedCornerShape(50)).background(Color.White).padding(horizontal = 14.dp, vertical = 5.dp))
            }
        }
    }
}

@Composable
private fun TargetCard(studied: Int, target: Int, progress: Float) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 20.dp).padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Target Harian", style = rounded(13, Wt.Heavy), color = c.primaryText, modifier = Modifier.weight(1f))
            Text("$studied/$target", style = rounded(13, Wt.Heavy), color = c.secondaryText)
        }
        Spacer(Modifier.height(10.dp))
        Box(Modifier.fillMaxWidth().height(10.dp).clip(RoundedCornerShape(50)).background(c.track)) {
            Box(Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(10.dp).clip(RoundedCornerShape(50)).background(Brush.horizontalGradient(IchigoPalette.AccentGradient)))
        }
    }
}

@Composable
private fun StatsGrid(state: ProfileUiState) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(Icons.Filled.Bookmark, IchigoPalette.Blue, "${state.totalCards}", "kartu", "total", Modifier.weight(1f))
            StatTile(Icons.Filled.CheckCircle, IchigoPalette.Success, "${state.studiedToday}", "kartu", "belajar", Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(Icons.Filled.LocalFireDepartment, IchigoPalette.Caution, "${state.streak}", "hari", "streak", Modifier.weight(1f))
            StatTile(Icons.Filled.Star, IchigoPalette.IndigoDeep, "${state.mastered}", "kartu", "mastered", Modifier.weight(1f))
        }
    }
}

@Composable
private fun StatTile(icon: ImageVector, tint: Color, value: String, unit: String, caption: String, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(modifier.ichigoCard(c.surface, c.cardShadow, radius = 18.dp).padding(14.dp)) {
        Box(Modifier.size(32.dp).clip(RoundedCornerShape(10.dp)).background(c.softTint(tint)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = tint, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Text(value, style = rounded(24, Wt.Heavy), color = c.primaryText)
            Spacer(Modifier.size(4.dp))
            Text(unit, style = rounded(11, Wt.Bold), color = c.secondaryText, modifier = Modifier.padding(bottom = 3.dp))
        }
        Text(caption, style = rounded(11, Wt.Bold), color = c.secondaryText)
    }
}

@Composable
private fun AnswerSummary(state: ProfileUiState) {
    val c = IchigoTheme.colors
    val s = state.summary
    Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 20.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Ringkasan Jawaban", style = rounded(15, Wt.Heavy), color = c.primaryText)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            AnswerPill("Ulang", s.againCount, IchigoPalette.Danger, Modifier.weight(1f))
            AnswerPill("Susah", s.hardCount, IchigoPalette.Caution, Modifier.weight(1f))
            AnswerPill("Bagus", s.goodCount, IchigoPalette.Accent, Modifier.weight(1f))
            AnswerPill("Mudah", s.easyCount, IchigoPalette.Success, Modifier.weight(1f))
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(c.track))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Akurasi keseluruhan", style = rounded(13, Wt.Semibold), color = c.secondaryText, modifier = Modifier.weight(1f))
            Text("${(s.accuracy * 100).roundToInt()}%", style = rounded(15, Wt.Heavy), color = c.primaryText)
        }
    }
}

@Composable
private fun AnswerPill(label: String, count: Int, tint: Color, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(modifier.clip(RoundedCornerShape(12.dp)).background(c.softTint(tint)).padding(vertical = 9.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("$count", style = rounded(18, Wt.Heavy), color = tint)
        Text(label, style = rounded(10, Wt.Bold), color = c.secondaryText)
    }
}
