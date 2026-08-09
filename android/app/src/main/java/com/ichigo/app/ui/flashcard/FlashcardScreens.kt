package com.ichigo.app.ui.flashcard

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.CircularProgressIndicator
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
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardLoadState
import com.ichigo.app.data.flashcard.FlashcardMode
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.ui.browse.BackButton
import com.ichigo.app.ui.browse.LargeScreen
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow
import kotlin.math.roundToInt

private fun modeIcon(mode: FlashcardMode): ImageVector =
    if (mode == FlashcardMode.VOCABULARY) Icons.Filled.Book else Icons.AutoMirrored.Filled.Article

/** Port of `FlashcardTypeSelectionView` — the mode picker. */
@Composable
fun FlashcardModeScreen(onBack: () -> Unit, onOpenMode: (FlashcardMode) -> Unit) {
    val c = IchigoTheme.colors
    LargeScreen(title = "Flashcard", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 18.dp).padding(top = 4.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                FlashcardMode.allCases.forEach { mode ->
                    ModeCard(mode, Modifier.weight(1f)) { onOpenMode(mode) }
                }
            }
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(c.softTint(IchigoPalette.Accent)).padding(16.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Box(Modifier.size(34.dp).clip(RoundedCornerShape(11.dp)).background(c.surface), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Info, null, tint = IchigoPalette.Accent, modifier = Modifier.size(18.dp))
                }
                Spacer(Modifier.width(12.dp))
                Column {
                    Text("Cara kerja review", style = rounded(13, Wt.Bold), color = c.primaryText)
                    Text(
                        "Tap kartu untuk melihat jawaban, lalu nilai seberapa mudah kamu mengingatnya. Kartu dijadwalkan ulang dengan FSRS:",
                        style = rounded(12, Wt.Medium),
                        color = c.secondaryText,
                    )
                    Spacer(Modifier.height(10.dp))
                    GradeIntervalRow("Ulang", "diulang ~1 menit lagi", IchigoPalette.Danger)
                    GradeIntervalRow("Susah", "diulang ~1–10 menit lagi", IchigoPalette.Caution)
                    GradeIntervalRow("Bagus", "~10 menit, lalu ~1 hari saat lulus", IchigoPalette.Accent)
                    GradeIntervalRow("Mudah", "langsung lulus, ~3 hari", IchigoPalette.Success)
                }
            }
        }
    }
}

/** One line in the "Cara kerja review" card: grade dot + name + when it repeats. */
@Composable
private fun GradeIntervalRow(grade: String, interval: String, color: Color) {
    val c = IchigoTheme.colors
    Row(Modifier.fillMaxWidth().padding(vertical = 3.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(8.dp).clip(CircleShape).background(color))
        Spacer(Modifier.width(8.dp))
        Text(grade, style = rounded(12, Wt.Bold), color = color, modifier = Modifier.width(52.dp))
        Text(interval, style = rounded(12, Wt.Medium), color = c.secondaryText)
    }
}

@Composable
private fun ModeCard(mode: FlashcardMode, modifier: Modifier, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Column(
        modifier.ichigoCard(c.surface, c.cardShadow).clickable(onClick = onClick).padding(vertical = 20.dp, horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            Modifier.size(56.dp).softShadow(mode.gradient[1].copy(alpha = 0.34f), 9.dp, 17.dp, offsetY = 5.dp).clip(RoundedCornerShape(17.dp)).background(Brush.linearGradient(mode.gradient)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(modeIcon(mode), null, tint = Color.White, modifier = Modifier.size(26.dp))
        }
        Spacer(Modifier.height(14.dp))
        Text(mode.title, style = rounded(16, Wt.Bold), color = c.primaryText)
        Spacer(Modifier.height(3.dp))
        Text(mode.subtitle, style = rounded(12, Wt.Medium), color = c.secondaryText, textAlign = TextAlign.Center)
    }
}

/** Port of `FlashcardLevelView` — deck level picker with due badges. */
@Composable
fun FlashcardLevelScreen(
    onBack: () -> Unit,
    onOpenLevel: (FlashcardMode, ContentLevel) -> Unit,
    viewModel: FlashcardLevelViewModel = hiltViewModel(),
) {
    val stats by viewModel.stats.collectAsStateWithLifecycle()
    LargeScreen(title = "Flashcard ${viewModel.mode.title}", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            viewModel.levels.forEach { level ->
                if (level.isLocked) {
                    FlashcardLockedCard(level)
                } else {
                    FlashcardUnlockedCard(level, stats[level.id]?.total, stats[level.id]?.due ?: 0) {
                        onOpenLevel(viewModel.mode, level)
                    }
                }
            }
        }
    }
}

@Composable
private fun FlashcardUnlockedCard(level: ContentLevel, total: Int?, due: Int, onClick: () -> Unit) {
    val c = IchigoTheme.colors
    Row(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow).clickable(onClick = onClick).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)).background(level.bgColor), contentAlignment = Alignment.Center) {
            Text(level.id, style = rounded(18, Wt.Black), color = level.color)
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(level.name, style = rounded(17, Wt.Bold), color = c.primaryText, modifier = Modifier.weight(1f))
                if (due > 0) {
                    Text("$due due", style = rounded(11, Wt.Bold), color = Color.White, modifier = Modifier.clip(RoundedCornerShape(10.dp)).background(level.color).padding(horizontal = 8.dp, vertical = 3.dp))
                    Spacer(Modifier.width(8.dp))
                }
                Icon(Icons.Filled.ChevronRight, null, tint = c.secondaryText, modifier = Modifier.size(18.dp))
            }
            Spacer(Modifier.height(5.dp))
            Text(level.description, style = rounded(13), color = c.secondaryText)
            Text("${total ?: "-"} kartu • bebas pilih deck", style = rounded(11, Wt.Semibold), color = level.color)
        }
    }
}

@Composable
private fun FlashcardLockedCard(level: ContentLevel) {
    val c = IchigoTheme.colors
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(c.surface.copy(alpha = 0.5f)).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)).background(Color.Gray.copy(alpha = 0.1f)), contentAlignment = Alignment.Center) {
            Text(level.id, style = rounded(18, Wt.Black), color = c.secondaryText)
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(level.name, style = rounded(17, Wt.Bold), color = c.secondaryText, modifier = Modifier.weight(1f))
                Icon(Icons.Filled.Lock, null, tint = c.secondaryText, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(4.dp))
                Text("Terkunci", style = rounded(11, Wt.Semibold), color = c.secondaryText)
            }
            Text(level.description, style = rounded(13), color = c.secondaryText.copy(alpha = 0.6f))
        }
    }
}

// -- Session --------------------------------------------------------------

@Composable
fun FlashcardSessionScreen(onBack: () -> Unit, viewModel: FlashcardSessionViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            BackButton(onBack)
            Spacer(Modifier.width(14.dp))
            Text("Flashcard ${state.modeTitle}", style = rounded(17, Wt.Bold), color = c.primaryText)
        }
        when (val s = state.loadState) {
            FlashcardLoadState.Idle, FlashcardLoadState.Loading -> CenterMessage { CircularProgressIndicator(color = IchigoPalette.Accent); Spacer(Modifier.height(12.dp)); Text("Memuat sesi belajar...", style = rounded(14), color = c.secondaryText) }
            FlashcardLoadState.Empty, FlashcardLoadState.ComingSoon -> EmptySession("Belum ada kartu", "Semua kartu sudah selesai atau belum ada kartu due.")
            is FlashcardLoadState.Failed -> EmptySession("Gagal memuat", s.message)
            else -> if (state.finished) FinishedView(state, onBack) else ReviewView(state, viewModel)
        }
    }
}

@Composable
private fun ReviewView(state: com.ichigo.app.ui.flashcard.SessionUiState, vm: FlashcardSessionViewModel) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize()) {
        StatsCard(state)
        FlipCard(state, Modifier.weight(1f).padding(horizontal = 18.dp, vertical = 16.dp)) { vm.reveal() }
        if (state.isRevealed) GradeButtons(vm) else Spacer(Modifier.height(48.dp).padding(bottom = 14.dp))
    }
}

@Composable
private fun StatsCard(state: com.ichigo.app.ui.flashcard.SessionUiState) {
    val c = IchigoTheme.colors
    Column(Modifier.padding(horizontal = 18.dp).fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 18.dp, shadowRadius = 8.dp, shadowY = 3.dp).padding(horizontal = 16.dp, vertical = 13.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("JLPT ${state.levelId}", style = rounded(12, Wt.Bold), color = IchigoPalette.Accent, modifier = Modifier.weight(1f))
            Text(state.positionText, style = rounded(12, Wt.Semibold), color = c.secondaryText)
        }
        Spacer(Modifier.height(8.dp))
        Box(Modifier.fillMaxWidth().height(7.dp).clip(RoundedCornerShape(50)).background(c.track)) {
            Box(Modifier.fillMaxWidth(state.progressValue.coerceIn(0f, 1f)).height(7.dp).clip(RoundedCornerShape(50)).background(Brush.horizontalGradient(IchigoPalette.AccentGradient)))
        }
        Spacer(Modifier.height(11.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            CountPill(state.remainingNew, "due", IchigoPalette.Accent, Modifier.weight(1f))
            CountPill(state.remainingLearning, "ulang", IchigoPalette.Danger, Modifier.weight(1f))
            CountPill(state.remainingReview, "hafal", IchigoPalette.Success, Modifier.weight(1f))
        }
    }
}

@Composable
private fun CountPill(count: Int, label: String, color: Color, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Row(modifier.clip(RoundedCornerShape(11.dp)).background(c.softTint(color)).padding(vertical = 7.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(7.dp).clip(CircleShape).background(color))
        Spacer(Modifier.width(6.dp))
        Text("$count", style = rounded(15, Wt.Bold), color = color)
        Spacer(Modifier.width(6.dp))
        Text(label, style = rounded(10, Wt.Bold), color = color.copy(alpha = 0.7f))
    }
}

@Composable
private fun FlipCard(state: com.ichigo.app.ui.flashcard.SessionUiState, modifier: Modifier, onReveal: () -> Unit) {
    val c = IchigoTheme.colors
    val item = state.currentCard ?: return
    Box(
        modifier
            .softShadow(c.cardShadow, 13.dp, Dimens.HeroRadius, offsetY = 10.dp)
            .clip(RoundedCornerShape(Dimens.HeroRadius))
            .background(c.surface)
            .clickable(onClick = onReveal),
    ) {
        Box(Modifier.fillMaxWidth().height(5.dp).background(Brush.horizontalGradient(IchigoPalette.AccentGradient)))
        Column(Modifier.fillMaxSize().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text(item.front, style = rounded(46, Wt.Bold), color = c.primaryText, textAlign = TextAlign.Center)
            if (state.isRevealed) {
                if (item.revealedTitle.isNotEmpty()) {
                    Spacer(Modifier.height(6.dp))
                    Text(item.revealedTitle, style = rounded(17, Wt.Bold), color = c.secondaryText)
                }
                Spacer(Modifier.height(4.dp))
                Text(item.revealedBody, style = rounded(24, Wt.Bold), color = c.primaryText, textAlign = TextAlign.Center)
                if (item.revealedTag.isNotEmpty()) {
                    Spacer(Modifier.height(10.dp))
                    Text(item.revealedTag, style = rounded(12, Wt.Bold), color = Color.White, modifier = Modifier.clip(RoundedCornerShape(50)).background(Brush.linearGradient(IchigoPalette.AccentGradient)).padding(horizontal = 16.dp, vertical = 6.dp))
                }
            } else {
                Spacer(Modifier.height(6.dp))
                Text("Tap kartu untuk melihat jawaban", style = rounded(13, Wt.Medium), color = IchigoPalette.Placeholder)
            }
        }
    }
}

@Composable
private fun GradeButtons(vm: FlashcardSessionViewModel) {
    Column(Modifier.padding(horizontal = 18.dp, vertical = 14.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
            GradeButton(FlashcardGrade.AGAIN, IchigoPalette.Danger, Modifier.weight(1f), vm)
            GradeButton(FlashcardGrade.HARD, IchigoPalette.Caution, Modifier.weight(1f), vm)
        }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
            GradeButton(FlashcardGrade.GOOD, IchigoPalette.Accent, Modifier.weight(1f), vm)
            GradeButton(FlashcardGrade.EASY, IchigoPalette.Success, Modifier.weight(1f), vm)
        }
    }
}

@Composable
private fun GradeButton(grade: FlashcardGrade, color: Color, modifier: Modifier, vm: FlashcardSessionViewModel) {
    Box(
        modifier.height(48.dp).softShadow(color.copy(alpha = 0.3f), 8.dp, 15.dp, offsetY = 5.dp).clip(RoundedCornerShape(15.dp)).background(color).clickable { vm.submit(grade) },
        contentAlignment = Alignment.Center,
    ) {
        Text(grade.title, style = rounded(15, Wt.Bold), color = Color.White)
    }
}

@Composable
private fun FinishedView(state: com.ichigo.app.ui.flashcard.SessionUiState, onBack: () -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(bottom = 28.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(20.dp))
        Text(if (state.sessionAccuracy >= 0.8) "🎉" else "💪", style = rounded(60))
        Spacer(Modifier.height(8.dp))
        Text("Sesi Selesai!", style = rounded(26, Wt.Heavy), color = c.primaryText)
        Text("JLPT ${state.levelId} • ${state.modeTitle}", style = rounded(13, Wt.Semibold), color = c.secondaryText)
        Spacer(Modifier.height(18.dp))
        // summary card
        Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow).padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("${(state.sessionAccuracy * 100).roundToInt()}%", style = rounded(44, Wt.Heavy), color = IchigoPalette.Accent)
            Text("Akurasi sesi ini", style = rounded(13, Wt.Semibold), color = c.secondaryText)
            Spacer(Modifier.height(16.dp))
            Box(Modifier.fillMaxWidth().height(1.dp).background(c.track))
            Spacer(Modifier.height(16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                SummaryStat(state.sessionCorrect, "Benar", IchigoPalette.Success, Modifier.weight(1f))
                SummaryStat(state.sessionWrong, "Ulang", IchigoPalette.Danger, Modifier.weight(1f))
                SummaryStat(state.sessionTotal, "Kartu", IchigoPalette.Accent, Modifier.weight(1f))
            }
        }
        Spacer(Modifier.height(18.dp))
        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.softTint(IchigoPalette.Caution)).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("🔥", style = rounded(26))
            Spacer(Modifier.width(12.dp))
            Column {
                Text("Streak ${state.currentStreak} hari", style = rounded(15, Wt.Heavy), color = c.primaryText)
                Text("Belajar setiap hari agar runtutannya tidak putus.", style = rounded(12, Wt.Medium), color = c.secondaryText)
            }
        }
        Spacer(Modifier.height(18.dp))
        Box(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(IchigoPalette.Accent).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
            Text("Kembali", style = rounded(16, Wt.Bold), color = Color.White)
        }
    }
}

@Composable
private fun SummaryStat(value: Int, label: String, color: Color, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(modifier.clip(RoundedCornerShape(14.dp)).background(c.softTint(color)).padding(vertical = 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("$value", style = rounded(24, Wt.Heavy), color = color)
        Text(label, style = rounded(11, Wt.Bold), color = c.secondaryText)
    }
}

@Composable
private fun EmptySession(title: String, subtitle: String) {
    val c = IchigoTheme.colors
    CenterMessage {
        Text(title, style = rounded(18, Wt.Bold), color = c.primaryText)
        Spacer(Modifier.height(6.dp))
        Text(subtitle, style = rounded(13), color = c.secondaryText, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 28.dp))
    }
}

@Composable
private fun CenterMessage(content: @Composable () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) { content() }
}
