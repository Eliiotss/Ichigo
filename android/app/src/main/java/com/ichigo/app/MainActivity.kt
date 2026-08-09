package com.ichigo.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import com.ichigo.app.data.backup.DriveSyncManager
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.ui.IchigoApp
import com.ichigo.app.ui.settings.AppearanceViewModel
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.util.ReminderScheduler
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Single-activity host, matching the iOS `IchigoApp` scene that hosts `RootView`.
 *
 * `RootView` in SwiftUI pre-warms datasets behind a splash then cross-fades to
 * `ContentView`; here the platform SplashScreen covers the cold start and the
 * Compose [IchigoApp] runs its own in-app splash (SplashScreen composable) that
 * mirrors `RootView.SplashView`.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val appearanceViewModel: AppearanceViewModel by viewModels()

    @Inject lateinit var driveSync: DriveSyncManager
    @Inject lateinit var prefs: AppPreferences
    @Inject lateinit var reminder: ReminderScheduler

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // Re-arm the daily reminder if it was enabled (covers reinstall/update).
        lifecycleScope.launch {
            if (prefs.notifEnabled.first()) reminder.schedule(prefs.notifHour.first())
        }
        setContent {
            // The user's Sistem/Terang/Gelap choice, persisted like the iOS
            // `AppAppearance` @AppStorage value. Applied at the root so every
            // screen — including dialogs — switches at once.
            val appearance by appearanceViewModel.appearance.collectAsStateWithLifecycle()
            IchigoTheme(appearance = appearance) {
                IchigoApp()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Pull-merge on foreground when auto-sync is on (iOS scenePhase).
        lifecycleScope.launch { driveSync.autoSyncIfEnabled() }
    }
}
