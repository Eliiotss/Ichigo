package com.ichigo.app.ui.settings

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ichigo.app.ui.components.ThemeSlideToggle
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

/** Port of `SettingsView`. Google Drive sync shows a "Segera Hadir" placeholder for now. */
@Composable
fun SettingsScreen(viewModel: SettingsViewModel = hiltViewModel()) {
    val c = IchigoTheme.colors
    val state by viewModel.state.collectAsStateWithLifecycle()
    val systemDark = androidx.compose.foundation.isSystemInDarkTheme()
    val context = LocalContext.current
    var showReset by remember { mutableStateOf(false) }

    LaunchedEffect(systemDark) { viewModel.syncEffectiveDark(systemDark) }

    val notifLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        viewModel.setNotifEnabled(granted)
    }

    LazyColumn(
        Modifier.fillMaxWidth().background(c.page),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 28.dp),
    ) {
        item {
            Text("Pengaturan", style = rounded(32, Wt.Heavy), color = c.primaryText, modifier = Modifier.padding(horizontal = 18.dp).padding(top = 6.dp, bottom = 8.dp))
        }

        item {
            Section("PROFIL", "Nama pengguna tampil di Beranda dan halaman Profil.") {
                SettingsCard {
                    NameRow(state.displayName, viewModel::setName)
                }
            }
        }

        item {
            Section("PREFERENSI", "Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.") {
                SettingsCard {
                    SettingsRow(if (state.isDark) Icons.Filled.DarkMode else Icons.Filled.LightMode, listOf(IchigoPalette.IndigoSoft, IchigoPalette.IndigoDeep), "Mode Tampilan") {
                        ThemeSlideToggle(state.isDark) { viewModel.setDark(it) }
                    }
                    SettingsRow(Icons.Filled.Notifications, listOf(IchigoPalette.Indigo, IchigoPalette.IndigoDeep), "Pengingat Belajar") {
                        Switch(
                            checked = state.notifEnabled,
                            onCheckedChange = { on ->
                                if (on && Build.VERSION.SDK_INT >= 33 &&
                                    ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
                                ) {
                                    notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                } else {
                                    viewModel.setNotifEnabled(on)
                                }
                            },
                            colors = SwitchDefaults.colors(checkedTrackColor = IchigoPalette.Accent),
                        )
                    }
                    if (state.notifEnabled) {
                        SettingsRow(Icons.Filled.Schedule, listOf(IchigoPalette.Teal, IchigoPalette.TealDeep), "Waktu pengingat") {
                            Stepper("jam ${state.notifHour}:00", viewModel::decNotifHour, viewModel::incNotifHour)
                        }
                    }
                    SettingsRow(Icons.Filled.GpsFixed, listOf(IchigoPalette.Violet, IchigoPalette.VioletDeep), "Target Harian") {
                        Stepper("${state.dailyTarget} kartu", viewModel::decTarget, viewModel::incTarget)
                    }
                    SettingsRow(Icons.Filled.Language, listOf(IchigoPalette.Blue, IchigoPalette.IndigoDeep), "Bahasa", showDivider = false) {
                        Text("Bahasa Indonesia", style = rounded(16, Wt.Semibold), color = c.secondaryText)
                    }
                }
            }
        }

        item {
            Section("AKUN & SINKRONISASI", "Sinkronisasi progres via Google Drive akan hadir di pembaruan berikutnya.") {
                SettingsCard {
                    SettingsRow(Icons.Filled.CloudOff, listOf(IchigoPalette.Teal, IchigoPalette.TealDeep), "Sinkronisasi Google Drive", showDivider = false) {
                        Text("Segera Hadir", style = rounded(14, Wt.Semibold), color = c.secondaryText)
                    }
                }
            }
        }

        item {
            Section("DATA BELAJAR", "Reset hanya menghapus progres flashcard lokal, review log, streak, dan pengaturan FSRS.") {
                SettingsCard {
                    Row(
                        Modifier.fillMaxWidth().clickable { showReset = true }.padding(start = 16.dp, end = 16.dp, top = 11.dp, bottom = 11.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        SettingsIcon(Icons.Filled.Delete, listOf(IchigoPalette.DangerSoft, IchigoPalette.Danger))
                        Spacer(Modifier.size(12.dp))
                        Text("Reset Semua Progress Flashcard", style = rounded(16, Wt.Semibold), color = c.primaryText)
                    }
                }
            }
        }
    }

    if (showReset) {
        AlertDialog(
            onDismissRequest = { showReset = false },
            title = { Text("Reset progress flashcard?", style = rounded(18, Wt.Bold), color = c.primaryText) },
            text = { Text("Tindakan ini tidak bisa dibatalkan. Data Kanji, Grammar, Vocabulary tidak akan dihapus.", style = rounded(14), color = c.secondaryText) },
            confirmButton = { TextButton(onClick = { viewModel.resetAll(); showReset = false }) { Text("Reset", color = IchigoPalette.Danger) } },
            dismissButton = { TextButton(onClick = { showReset = false }) { Text("Batal", color = c.secondaryText) } },
            containerColor = c.surface,
        )
    }
}

@Composable
private fun Section(title: String, footer: String, content: @Composable () -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.padding(top = 14.dp)) {
        Text(title, style = rounded(12, Wt.Heavy), color = c.secondaryText, modifier = Modifier.padding(horizontal = 20.dp))
        Spacer(Modifier.height(8.dp))
        content()
        Spacer(Modifier.height(8.dp))
        Text(footer, style = rounded(12, Wt.Medium), color = c.secondaryText, modifier = Modifier.padding(horizontal = 20.dp))
    }
}

@Composable
private fun SettingsCard(content: @Composable () -> Unit) {
    val c = IchigoTheme.colors
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 18.dp).clip(RoundedCornerShape(18.dp)).background(c.surface),
    ) { content() }
}

@Composable
private fun SettingsIcon(icon: ImageVector, colors: List<Color>) {
    Box(Modifier.size(29.dp).clip(RoundedCornerShape(8.dp)).background(Brush.linearGradient(colors)), contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun SettingsRow(icon: ImageVector, colors: List<Color>, title: String, showDivider: Boolean = true, trailing: @Composable () -> Unit) {
    val c = IchigoTheme.colors
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        SettingsIcon(icon, colors)
        Spacer(Modifier.size(12.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 11.dp)) {
                Text(title, style = rounded(16, Wt.Semibold), color = c.primaryText, modifier = Modifier.weight(1f))
                Spacer(Modifier.size(8.dp))
                trailing()
            }
            if (showDivider) Box(Modifier.fillMaxWidth().height(1.dp).background(c.track))
        }
    }
}

@Composable
private fun NameRow(name: String, onChange: (String) -> Unit) {
    val c = IchigoTheme.colors
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
        SettingsIcon(Icons.Filled.Person, listOf(IchigoPalette.BlueLight, IchigoPalette.Blue))
        Spacer(Modifier.size(12.dp))
        Text("Nama Pengguna", style = rounded(16, Wt.Semibold), color = c.primaryText)
        Spacer(Modifier.weight(1f))
        BasicTextField(
            value = name,
            onValueChange = onChange,
            singleLine = true,
            textStyle = rounded(16, Wt.Semibold).merge(androidx.compose.ui.text.TextStyle(color = c.primaryText, textAlign = TextAlign.End)),
            cursorBrush = SolidColor(IchigoPalette.Accent),
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun Stepper(label: String, onMinus: () -> Unit, onPlus: () -> Unit) {
    val c = IchigoTheme.colors
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = rounded(14, Wt.Semibold), color = c.secondaryText)
        Spacer(Modifier.size(10.dp))
        Row(Modifier.clip(RoundedCornerShape(8.dp)).background(c.track)) {
            Box(Modifier.size(34.dp, 30.dp).clickable(onClick = onMinus), contentAlignment = Alignment.Center) {
                Text("−", style = rounded(18, Wt.Bold), color = c.primaryText)
            }
            Box(Modifier.size(1.dp, 30.dp).background(c.hairline))
            Box(Modifier.size(34.dp, 30.dp).clickable(onClick = onPlus), contentAlignment = Alignment.Center) {
                Text("+", style = rounded(18, Wt.Bold), color = c.primaryText)
            }
        }
    }
}
