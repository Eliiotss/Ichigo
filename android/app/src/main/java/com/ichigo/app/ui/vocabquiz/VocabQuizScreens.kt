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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.vocabularyLevels
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

/** One Vocab-quiz session: kanji prompt, 4 furigana choices, reveal the meaning. */
@Composable
fun VocabQuizSessionScreen(onBack: () -> Unit, viewModel: VocabQuizViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize().background(c.page)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Kuis Vocab", style = rounded(22, Wt.Heavy), color = c.primaryText, modifier = Modifier.weight(1f))
            Box(
                Modifier.height(40.dp).softShadow(c.cardShadow, 6.dp, 20.dp, offsetY = 2.dp).clip(RoundedCornerShape(50)).background(c.surface).clickable(onClick = onBack).padding(horizontal = 20.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("Tutup", style = rounded(15, Wt.Semibold), color = c.primaryText)
            }
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

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(16.dp))
        // stats card
        Column(Modifier.padding(horizontal = 20.dp).fillMaxWidth().ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp).padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Soal ${state.currentIndex + 1} / ${state.deckSize}", style = rounded(15, Wt.Bold), color = c.primaryText, modifier = Modifier.weight(1f))
                Text("${state.sessionCorrect} benar", style = rounded(15, Wt.Bold), color = QuizAccent)
            }
            Spacer(Modifier.height(8.dp))
            Bar(state.progressValue, QuizAccent, 6)
        }
        Spacer(Modifier.height(16.dp))
        // question card — the kanji word
        Box(
            Modifier.padding(horizontal = 20.dp).fillMaxWidth().height(220.dp)
                .softShadow(QuizAccent.copy(alpha = 0.28f), 16.dp, Dimens.HeroRadius, offsetY = 8.dp)
                .clip(RoundedCornerShape(Dimens.HeroRadius)).background(Brush.linearGradient(QuizGradient)).clipToBounds(),
            contentAlignment = Alignment.Center,
        ) {
            Box(Modifier.size(170.dp).offset(x = 120.dp, y = (-55).dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f)))
            Box(Modifier.size(150.dp).offset(x = (-55).dp, y = 120.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.10f)))
            Text(q.kanji, style = rounded(if (q.kanji.length > 3) 60 else 80), color = Color.White, textAlign = TextAlign.Center)
        }
        Spacer(Modifier.height(14.dp))
        Text("Pilih bacaan yang benar", style = rounded(14), color = c.secondaryText)
        Spacer(Modifier.height(12.dp))
        // choices 2x2
        Column(Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            q.choices.chunked(2).forEach { rowChoices ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    rowChoices.forEach { choice ->
                        ChoiceButton(choice, q.correctAnswer, state.selectedAnswer, state.isAnswered, Modifier.weight(1f)) { vm.handleAnswer(choice) }
                    }
                    if (rowChoices.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
        // After answering: the correct furigana + the meaning below it.
        state.revealedMeaning?.let { meaning ->
            Spacer(Modifier.height(16.dp))
            Column(
                Modifier.padding(horizontal = 20.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.softTint(IchigoPalette.Success)).padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(q.correctAnswer, style = rounded(22, Wt.Heavy), color = c.primaryText)
                Spacer(Modifier.height(4.dp))
                Text(meaning, style = rounded(15, Wt.Medium), color = c.secondaryText, textAlign = TextAlign.Center)
            }
            Spacer(Modifier.height(14.dp))
            Box(
                Modifier.padding(horizontal = 20.dp).fillMaxWidth().height(52.dp).clip(RoundedCornerShape(18.dp)).background(QuizAccent).clickable { vm.next() },
                contentAlignment = Alignment.Center,
            ) {
                Text(if (state.isLast) "Selesai" else "Lanjut →", style = rounded(16, Wt.Bold), color = Color.White)
            }
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun ChoiceButton(label: String, correct: String, selected: String?, isAnswered: Boolean, modifier: Modifier, onClick: () -> Unit) {
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
        modifier.height(64.dp).softShadow(c.cardShadow, 8.dp, 18.dp, offsetY = 3.dp).clip(RoundedCornerShape(18.dp)).background(bg)
            .then(if (isAnswered) Modifier else Modifier.clickable(onClick = onClick)),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = rounded(18, Wt.Bold), color = textColor)
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

@Composable
private fun Bar(value: Float, color: Color, heightDp: Int) {
    val c = IchigoTheme.colors
    Box(Modifier.fillMaxWidth().height(heightDp.dp).clip(RoundedCornerShape(50)).background(c.track)) {
        Box(Modifier.fillMaxWidth(value.coerceIn(0f, 1f)).height(heightDp.dp).clip(RoundedCornerShape(50)).background(color))
    }
}
