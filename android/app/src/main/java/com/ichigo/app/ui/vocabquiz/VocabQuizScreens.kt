package com.ichigo.app.ui.vocabquiz

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.vocabularyLevels
import com.ichigo.app.ui.browse.BackButton
import com.ichigo.app.ui.browse.LargeScreen
import com.ichigo.app.ui.browse.LockedLevelCard
import com.ichigo.app.ui.browse.UnlockedLevelCard
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow

private val QuizGradient = listOf(IchigoPalette.Teal, IchigoPalette.TealDeep)
private val QuizAccent = IchigoPalette.TealDeep

/** Level picker for the Vocab quiz — reuses the shared content-level cards. */
@Composable
fun VocabQuizLevelScreen(onBack: () -> Unit, onOpen: (ContentLevel) -> Unit) {
    LargeScreen(title = "Kuis Vocab", onBack = onBack) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                "Tebak bacaan (furigana) dari kanji. Kata yang salah akan muncul lagi sampai kamu kuasai.",
                style = rounded(13, Wt.Medium),
                color = IchigoTheme.colors.secondaryText,
            )
            vocabularyLevels.forEach { level ->
                if (level.isLocked) LockedLevelCard(level) else UnlockedLevelCard(level) { onOpen(level) }
            }
        }
    }
}

/**
 * One Vocab-quiz session. Laid out like the FSRS flashcard session — a fixed
 * header + stats card at the top, the question card flexing with `weight(1f)`,
 * and the answer grid pinned at the bottom — so it fits any screen **without
 * scrolling**. The choice font shrinks for long readings.
 */
@Composable
fun VocabQuizSessionScreen(onBack: () -> Unit, viewModel: VocabQuizViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            BackButton(onBack)
            Spacer(Modifier.width(14.dp))
            Text("Kuis Vocab", style = rounded(17, Wt.Bold), color = c.primaryText)
        }
        when {
            state.loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = QuizAccent)
            }
            state.empty -> Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Text("Belum ada kata berkanji di level ini", style = rounded(18, Wt.Bold), color = c.primaryText)
            }
            state.finished -> FinishedQuiz(state, onBack) { viewModel.restart() }
            state.question != null -> QuestionContent(state, viewModel)
        }
    }
}

@Composable
private fun QuestionContent(state: VocabQuizUiState, vm: VocabQuizViewModel) {
    val c = IchigoTheme.colors
    val q = state.question!!

    // Non-scrolling column: the question card takes the flexible middle, the
    // answers + reveal are pinned at the bottom (same shape as FlashcardSession).
    Column(Modifier.fillMaxSize()) {
        StatsCard(state)

        // Question card — flexes to fill, matching the flashcard FlipCard.
        Box(
            Modifier.weight(1f).padding(horizontal = 18.dp, vertical = 12.dp)
                .softShadow(c.cardShadow, 13.dp, Dimens.HeroRadius, offsetY = 10.dp)
                .clip(RoundedCornerShape(Dimens.HeroRadius)).background(c.surface),
        ) {
            Box(Modifier.fillMaxWidth().height(5.dp).background(Brush.horizontalGradient(QuizGradient)))
            Column(Modifier.fillMaxSize().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Text(q.kanji, style = rounded(kanjiFontFor(q.kanji), Wt.Bold), color = c.primaryText, textAlign = TextAlign.Center)
                Spacer(Modifier.height(8.dp))
                Text("Pilih bacaan yang benar", style = rounded(13, Wt.Medium), color = c.secondaryText)
            }
        }

        // Answers pinned at the bottom, styled like the FSRS grade grid.
        val choiceFont = choiceFontFor(q.choices)
        Column(Modifier.padding(horizontal = 18.dp).padding(bottom = 14.dp)) {
            q.choices.chunked(2).forEach { rowChoices ->
                Row(Modifier.fillMaxWidth().padding(top = 10.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    rowChoices.forEach { choice ->
                        ChoiceButton(choice, q.correctAnswer, state.selectedAnswer, state.isAnswered, choiceFont, Modifier.weight(1f)) { vm.handleAnswer(choice) }
                    }
                    if (rowChoices.size == 1) Spacer(Modifier.weight(1f))
                }
            }
            // After answering: the meaning appears right under the furigana choices.
            if (state.isAnswered) {
                Spacer(Modifier.height(12.dp))
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(c.softTint(IchigoPalette.Success)).padding(horizontal = 14.dp, vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(q.correctAnswer, style = rounded(18, Wt.Heavy), color = c.primaryText)
                    Spacer(Modifier.height(2.dp))
                    Text(q.meaning, style = rounded(15, Wt.Medium), color = c.secondaryText, textAlign = TextAlign.Center, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
                Spacer(Modifier.height(10.dp))
                Box(
                    Modifier.fillMaxWidth().height(50.dp).softShadow(QuizAccent.copy(alpha = 0.3f), 8.dp, 15.dp, offsetY = 5.dp).clip(RoundedCornerShape(15.dp)).background(QuizAccent).clickable { vm.next() },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(if (state.isLast) "Selesai" else "Lanjut →", style = rounded(16, Wt.Bold), color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun StatsCard(state: VocabQuizUiState) {
    val c = IchigoTheme.colors
    Column(Modifier.padding(horizontal = 18.dp).padding(top = 4.dp).fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 18.dp, shadowRadius = 8.dp, shadowY = 3.dp).padding(horizontal = 16.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Soal ${state.currentIndex + 1} / ${state.deckSize}", style = rounded(14, Wt.Bold), color = c.primaryText, modifier = Modifier.weight(1f))
            Text("${state.sessionCorrect} benar", style = rounded(14, Wt.Bold), color = QuizAccent)
        }
        Spacer(Modifier.height(8.dp))
        Box(Modifier.fillMaxWidth().height(7.dp).clip(RoundedCornerShape(50)).background(c.track)) {
            Box(Modifier.fillMaxWidth(state.progressValue.coerceIn(0f, 1f)).height(7.dp).clip(RoundedCornerShape(50)).background(QuizAccent))
        }
    }
}

@Composable
private fun ChoiceButton(
    label: String,
    correct: String,
    selected: String?,
    isAnswered: Boolean,
    fontSize: Int,
    modifier: Modifier,
    onClick: () -> Unit,
) {
    val c = IchigoTheme.colors
    val isCorrect = label == correct
    val isWrongSelected = label == selected && !isCorrect
    val bg = when {
        !isAnswered -> c.surface
        isCorrect -> IchigoPalette.Success
        isWrongSelected -> IchigoPalette.Danger
        else -> c.surface
    }
    val textColor = when {
        !isAnswered -> c.primaryText
        isCorrect || isWrongSelected -> Color.White
        else -> c.secondaryText
    }
    Box(
        modifier.height(58.dp).softShadow(c.cardShadow, 8.dp, 16.dp, offsetY = 3.dp).clip(RoundedCornerShape(16.dp)).background(bg)
            .then(if (isAnswered) Modifier else Modifier.clickable(onClick = onClick))
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            style = rounded(fontSize, Wt.Bold),
            color = textColor,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun FinishedQuiz(state: VocabQuizUiState, onBack: () -> Unit, onRestart: () -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize().padding(horizontal = 32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Text("🎉", style = rounded(72))
        Spacer(Modifier.height(16.dp))
        Text("Sesi Selesai!", style = rounded(28, Wt.Black), color = c.primaryText)
        Spacer(Modifier.height(8.dp))
        Text("Kamu menjawab benar ${state.sessionCorrect} dari ${state.deckSize} soal.", style = rounded(15), color = c.secondaryText, textAlign = TextAlign.Center)
        Spacer(Modifier.height(28.dp))
        Box(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(QuizAccent).clickable(onClick = onRestart), contentAlignment = Alignment.Center) {
            Text("Ulangi", style = rounded(16, Wt.Bold), color = Color.White)
        }
        Spacer(Modifier.height(12.dp))
        Box(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(c.surface).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
            Text("Kembali", style = rounded(16, Wt.Bold), color = c.primaryText)
        }
    }
}

/** Kanji prompt font: shrinks for longer words so it never overflows the card. */
private fun kanjiFontFor(kanji: String): Int = when (kanji.length) {
    1, 2 -> 60
    3 -> 50
    4 -> 42
    5 -> 34
    else -> 28
}

/** One shared choice font, sized from the longest reading so the 2×2 grid fits. */
private fun choiceFontFor(choices: List<String>): Int = when (choices.maxOfOrNull { it.length } ?: 0) {
    in 0..5 -> 18
    in 6..8 -> 16
    in 9..11 -> 14
    else -> 12
}
