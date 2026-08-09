package com.ichigo.app.ui.settings

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.ichigo.app.BuildConfig
import com.ichigo.app.R
import com.ichigo.app.ui.components.ScreenHeader
import com.ichigo.app.ui.components.ichigoCard
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** "Tentang Aplikasi" — version, package, privacy, licenses, and a short blurb. */
@Composable
fun AboutScreen(onBack: () -> Unit) {
    var showPrivacy by remember { mutableStateOf(false) }
    if (showPrivacy) {
        PrivacyScreen(onBack = { showPrivacy = false })
        return
    }

    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Tentang Aplikasi", onBack)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Hero: logo + version chip + tagline
            Column(
                Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 22.dp).padding(vertical = 26.dp, horizontal = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                // The wordmark is dark ink on transparent, so keep it on a cream
                // chip — otherwise it vanishes on the dark card in dark mode.
                Box(
                    Modifier.clip(RoundedCornerShape(18.dp)).background(Color(0xFFFCF9F4)).padding(horizontal = 24.dp, vertical = 16.dp),
                ) {
                    Image(
                        painter = painterResource(R.drawable.ic_splash_logo),
                        contentDescription = "IchiGo",
                        modifier = Modifier.height(52.dp),
                    )
                }
                Spacer(Modifier.height(16.dp))
                Text(
                    "Versi ${BuildConfig.VERSION_NAME}",
                    style = rounded(12, Wt.Heavy),
                    color = IchigoPalette.Accent,
                    modifier = Modifier.clip(RoundedCornerShape(50)).background(IchigoPalette.Accent.copy(alpha = 0.12f)).padding(horizontal = 14.dp, vertical = 6.dp),
                )
                Spacer(Modifier.height(14.dp))
                Text(
                    "Belajar bahasa Jepang JLPT — Kanji, Kosakata, Tata Bahasa, dan Kana — dengan flashcard berjadwal (FSRS).",
                    style = rounded(13, Wt.Medium),
                    color = c.secondaryText,
                    textAlign = TextAlign.Center,
                )
            }

            // Informasi
            SectionLabel("INFORMASI")
            Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 20.dp)) {
                InfoRow(Icons.Filled.Info, listOf(IchigoPalette.BlueLight, IchigoPalette.Blue), "Versi", showDivider = false) {
                    Text("v${BuildConfig.VERSION_NAME}", style = rounded(15, Wt.Semibold), color = c.secondaryText)
                }
            }

            // Legal
            SectionLabel("LEGAL")
            Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 20.dp)) {
                InfoRow(
                    Icons.Filled.Shield, listOf(IchigoPalette.Indigo, IchigoPalette.IndigoDeep), "Kebijakan Privasi",
                    showDivider = false,
                    onClick = { showPrivacy = true },
                ) {
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = c.secondaryText, modifier = Modifier.size(20.dp))
                }
            }

            // Blurb
            Column(Modifier.fillMaxWidth().ichigoCard(c.surface, c.cardShadow, radius = 20.dp).padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.FavoriteBorder, null, tint = IchigoPalette.Accent, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.size(8.dp))
                    Text("Tentang Ichigo", style = rounded(15, Wt.Heavy), color = c.primaryText)
                }
                Text(
                    "Ichigo dibuat untuk belajar bahasa Jepang secara mandiri. Semua progres " +
                        "tersimpan di perangkatmu; kamu bisa mencadangkannya kapan saja lewat " +
                        "Pengaturan → Cadangan Data.",
                    style = rounded(13, Wt.Medium),
                    color = c.secondaryText,
                )
            }

            Text("Dibuat untuk belajar mandiri.", style = rounded(12, Wt.Semibold), color = c.secondaryText, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        }
    }
}

/** Privacy policy — plain, honest, and accurate to how the app stores data. */
@Composable
private fun PrivacyScreen(onBack: () -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxSize().background(c.page)) {
        ScreenHeader("Kebijakan Privasi", onBack)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp).padding(top = 6.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text("Ringkasan", style = rounded(17, Wt.Heavy), color = c.primaryText)
            Para(
                "Semua data belajarmu disimpan LOKAL di perangkat ini. Ichigo tidak memiliki " +
                    "server dan tidak mengirim data pribadimu ke mana pun.",
            )

            Heading("Data yang disimpan (lokal)")
            Para(
                "• Progres flashcard, streak, statistik jawaban.\n" +
                    "• Nama pengguna dan preferensi (target harian, tema, jam pengingat).\n" +
                    "Semuanya berada di penyimpanan privat aplikasi (Room + DataStore).",
            )

            Heading("Cadangan data (file)")
            Para(
                "Fitur Cadangan Data membuat berkas .json yang SEPENUHNYA kamu kontrol. " +
                    "Ke mana berkas itu disimpan atau dibagikan (mis. diunggah ke Google Drive-mu) " +
                    "adalah pilihanmu; aplikasi tidak mengunggahnya otomatis.",
            )

            Heading("Google Drive (opsional)")
            Para(
                "Bila sinkronisasi Google Drive diaktifkan, aplikasi hanya mengakses folder " +
                    "privat miliknya sendiri di Drive-mu (appDataFolder) — bukan berkas Drive-mu " +
                    "yang lain. Pengembang tidak dapat melihat data tersebut.",
            )

            Heading("Izin")
            Para(
                "• Internet & status jaringan — hanya untuk sinkronisasi opsional.\n" +
                    "• Notifikasi — untuk pengingat belajar harian.\n" +
                    "Tidak ada akses ke kontak, lokasi, kamera, atau mikrofon.",
            )

            Heading("Pihak ketiga & analitik")
            Para("Tidak ada SDK analitik atau iklan. Tidak ada pelacakan.")

            Heading("Anak-anak")
            Para("Aplikasi tidak mengumpulkan data pribadi, sehingga aman digunakan segala usia.")

            Heading("Perubahan")
            Para("Kebijakan ini dapat diperbarui seiring pembaruan aplikasi.")
        }
    }
}

// ── small building blocks ──────────────────────────────────────────────────

@Composable
private fun SectionLabel(text: String) {
    Text(text, style = rounded(12, Wt.Heavy), color = IchigoTheme.colors.secondaryText, modifier = Modifier.padding(start = 4.dp))
}

@Composable
private fun InfoRow(
    icon: ImageVector,
    colors: List<Color>,
    title: String,
    showDivider: Boolean = true,
    onClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit,
) {
    val c = IchigoTheme.colors
    val base = Modifier.fillMaxWidth()
    Row(
        (if (onClick != null) base.clickable(onClick = onClick) else base).padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(30.dp).clip(RoundedCornerShape(9.dp)).background(Brush.linearGradient(colors)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = Color.White, modifier = Modifier.size(17.dp))
        }
        Spacer(Modifier.size(12.dp))
        Text(title, style = rounded(16, Wt.Semibold), color = c.primaryText, modifier = Modifier.weight(1f))
        trailing()
    }
    if (showDivider) Divider()
}

@Composable
private fun Divider() {
    Box(Modifier.fillMaxWidth().padding(start = 58.dp).height(1.dp).background(IchigoTheme.colors.track))
}

@Composable
private fun Heading(text: String) {
    Text(text, style = rounded(15, Wt.Heavy), color = IchigoTheme.colors.primaryText)
}

@Composable
private fun Para(text: String) {
    Text(text, style = rounded(13, Wt.Medium), color = IchigoTheme.colors.secondaryText)
}
