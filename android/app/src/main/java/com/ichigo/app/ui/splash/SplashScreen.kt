package com.ichigo.app.ui.splash

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow

/** Port of `RootView.SplashView` — app mark, name, and a real load-progress bar. */
@Composable
fun SplashScreen(onReady: () -> Unit, viewModel: SplashViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) { viewModel.prepare() }
    LaunchedEffect(state.isReady) { if (state.isReady) onReady() }

    Box(Modifier.fillMaxSize().background(c.page), contentAlignment = Alignment.Center) {
        Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.weight(1f))
            Box(
                Modifier
                    .size(104.dp)
                    .softShadow(IchigoPalette.Blue.copy(alpha = 0.35f), 20.dp, 30.dp, offsetY = 10.dp)
                    .clip(RoundedCornerShape(30.dp))
                    .background(Brush.linearGradient(listOf(IchigoPalette.BlueLight, IchigoPalette.Blue))),
                contentAlignment = Alignment.Center,
            ) {
                Text("🍓", style = rounded(50))
            }
            Spacer(Modifier.height(22.dp))
            Text("Ichigo", style = rounded(34, Wt.Heavy), color = c.primaryText)
            Spacer(Modifier.height(4.dp))
            Text("Belajar bahasa Jepang", style = rounded(14, Wt.Medium), color = c.secondaryText)
            Spacer(Modifier.weight(1f))

            Column(Modifier.fillMaxWidth().padding(horizontal = 48.dp).padding(bottom = 56.dp)) {
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(50))
                        .background(c.track),
                ) {
                    Box(
                        Modifier
                            .fillMaxWidth(state.progress.coerceIn(0f, 1f))
                            .height(6.dp)
                            .clip(RoundedCornerShape(50))
                            .background(Brush.horizontalGradient(listOf(IchigoPalette.BlueLight, IchigoPalette.Blue))),
                    )
                }
                Spacer(Modifier.height(12.dp))
                Text(state.statusText, style = rounded(13, Wt.Medium), color = c.secondaryText, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}
