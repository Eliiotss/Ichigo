package com.ichigo.app.ui.splash

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.R
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

// Brand colours of the Ichigo logo (cream ground + red mark).
private val SplashCream = Color(0xFFFCF9F4)
private val SplashRed = Color(0xFFE12A1E)
private val SplashRedLight = Color(0xFFF04438)
private val SplashInk = Color(0xFF6B655E)
private val SplashTrack = Color(0xFFEBE5DD)

/** Branded splash — the IchiGo wordmark on the cream ground with a load bar. */
@Composable
fun SplashScreen(onReady: () -> Unit, viewModel: SplashViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) { viewModel.prepare() }
    LaunchedEffect(state.isReady) { if (state.isReady) onReady() }

    Box(Modifier.fillMaxSize().background(SplashCream), contentAlignment = Alignment.Center) {
        Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.weight(1f))
            Image(
                painter = painterResource(R.drawable.ic_splash_logo),
                contentDescription = "Ichigo",
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxWidth(0.66f),
            )
            Spacer(Modifier.height(8.dp))
            Text("Belajar bahasa Jepang", style = rounded(14, Wt.Medium), color = SplashInk)
            Spacer(Modifier.weight(1f))

            Column(Modifier.fillMaxWidth().padding(horizontal = 48.dp).padding(bottom = 56.dp)) {
                Box(Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(50)).background(SplashTrack)) {
                    Box(
                        Modifier
                            .fillMaxWidth(state.progress.coerceIn(0f, 1f))
                            .height(6.dp)
                            .clip(RoundedCornerShape(50))
                            .background(Brush.horizontalGradient(listOf(SplashRedLight, SplashRed))),
                    )
                }
                Spacer(Modifier.height(12.dp))
                Text(state.statusText, style = rounded(13, Wt.Medium), color = SplashInk, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}
