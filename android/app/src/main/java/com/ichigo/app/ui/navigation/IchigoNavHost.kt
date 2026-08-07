package com.ichigo.app.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ichigo.app.ui.browse.ComingSoonScreen
import com.ichigo.app.ui.browse.GrammarDetailScreen
import com.ichigo.app.ui.browse.GrammarLevelScreen
import com.ichigo.app.ui.browse.GrammarListScreen
import com.ichigo.app.ui.browse.KanjiDetailScreen
import com.ichigo.app.ui.browse.KanjiLevelScreen
import com.ichigo.app.ui.browse.KanjiListScreen
import com.ichigo.app.ui.browse.VocabLevelScreen
import com.ichigo.app.ui.browse.VocabListScreen
import com.ichigo.app.ui.flashcard.FlashcardLevelScreen
import com.ichigo.app.ui.flashcard.FlashcardModeScreen
import com.ichigo.app.ui.flashcard.FlashcardSessionScreen
import com.ichigo.app.ui.hiragana.HiraganaScreen
import com.ichigo.app.ui.hiragana.KanaFlashcardScreen
import com.ichigo.app.ui.home.HomeScreen
import com.ichigo.app.ui.profile.ProfileScreen
import com.ichigo.app.ui.settings.SettingsScreen
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded

private data class Tab(val label: String, val icon: ImageVector)

private val tabs = listOf(
    Tab("Home", Icons.Filled.Home),
    Tab("Profile", Icons.Filled.Person),
    Tab("Pengaturan", Icons.Filled.Settings),
)

/**
 * Root scaffold: a bottom tab bar (Home / Profile / Pengaturan) mirroring the
 * iOS `TabView`, with the browsing + flashcard screens pushed on top of the Home
 * tab's own nav graph — exactly the SwiftUI `NavigationStack`-inside-`TabView`
 * shape. The bar stays visible across Home-stack pushes (as on iOS) and hides
 * only for the kana flashcard, which iOS presents as a modal sheet.
 */
@Composable
fun MainScaffold() {
    val c = IchigoTheme.colors
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    val homeNav = rememberNavController()

    val homeEntry by homeNav.currentBackStackEntryAsState()
    val homeRoute = homeEntry?.destination?.route
    val hideBar = selectedTab == 0 && homeRoute?.startsWith("hiragana/flashcard") == true

    Scaffold(
        containerColor = c.page,
        bottomBar = {
            if (!hideBar) {
                IchigoBottomBar(selectedTab) { tab ->
                    if (tab == 0 && selectedTab == 0) homeNav.popBackStack(Routes.HOME, inclusive = false)
                    selectedTab = tab
                }
            }
        },
    ) { padding ->
        val ld = LocalLayoutDirection.current
        Box(
            Modifier
                .fillMaxSize()
                .padding(
                    start = padding.calculateStartPadding(ld),
                    end = padding.calculateEndPadding(ld),
                    top = padding.calculateTopPadding(),
                    bottom = if (hideBar) 0.dp else padding.calculateBottomPadding(),
                ),
        ) {
            when (selectedTab) {
                0 -> HomeNavHost(homeNav, onOpenProfile = { selectedTab = 1 })
                1 -> ProfileScreen()
                2 -> SettingsScreen()
            }
        }
    }
}

@Composable
private fun IchigoBottomBar(selected: Int, onSelect: (Int) -> Unit) {
    val c = IchigoTheme.colors
    Column(Modifier.fillMaxWidth().background(c.tabBar)) {
        Box(Modifier.fillMaxWidth().height(0.5.dp).background(c.hairline))
        Row(
            Modifier.fillMaxWidth().navigationBarsPadding().padding(vertical = 8.dp),
        ) {
            tabs.forEachIndexed { index, tab ->
                val active = index == selected
                val tint = if (active) com.ichigo.app.ui.theme.IchigoPalette.Accent else c.secondaryText
                Column(
                    Modifier
                        .weight(1f)
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                        ) { onSelect(index) }
                        .padding(vertical = 4.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Icon(tab.icon, contentDescription = tab.label, tint = tint, modifier = Modifier.size(26.dp))
                    Spacer(Modifier.height(3.dp))
                    Text(tab.label, style = rounded(10, Wt.Semibold), color = tint)
                }
            }
        }
    }
}

/** The Home tab's nested nav graph — all browse + flashcard pushes. */
@Composable
private fun HomeNavHost(nav: NavHostController, onOpenProfile: () -> Unit) {
    NavHost(navController = nav, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenRoute = { nav.navigate(it) },
                onOpenProfile = onOpenProfile,
            )
        }

        // Kanji
        composable(Routes.KANJI) {
            KanjiLevelScreen(onBack = { nav.popBackStack() }) { level ->
                nav.navigate(Routes.kanjiList(level.jsonFile, level.id))
            }
        }
        composable(Routes.KANJI_LIST) { entry ->
            val jsonFile = entry.arguments?.getString(Routes.Arg.JSON_FILE).orEmpty()
            val levelId = entry.arguments?.getString(Routes.Arg.LEVEL_ID).orEmpty()
            KanjiListScreen(
                onBack = { nav.popBackStack() },
                onOpenItem = { itemId -> nav.navigate(Routes.kanjiDetail(jsonFile, levelId, itemId)) },
            )
        }
        composable(Routes.KANJI_DETAIL) { KanjiDetailScreen(onBack = { nav.popBackStack() }) }

        // Vocabulary
        composable(Routes.VOCAB) {
            VocabLevelScreen(onBack = { nav.popBackStack() }) { level ->
                nav.navigate(Routes.vocabList(level.jsonFile, level.id))
            }
        }
        composable(Routes.VOCAB_LIST) { VocabListScreen(onBack = { nav.popBackStack() }) }

        // Grammar
        composable(Routes.GRAMMAR) {
            GrammarLevelScreen(onBack = { nav.popBackStack() }) { level ->
                nav.navigate(Routes.grammarList(level.jsonFile, level.id))
            }
        }
        composable(Routes.GRAMMAR_LIST) { entry ->
            val jsonFile = entry.arguments?.getString(Routes.Arg.JSON_FILE).orEmpty()
            val levelId = entry.arguments?.getString(Routes.Arg.LEVEL_ID).orEmpty()
            GrammarListScreen(
                onBack = { nav.popBackStack() },
                onOpenItem = { itemId -> nav.navigate(Routes.grammarDetail(jsonFile, levelId, itemId)) },
            )
        }
        composable(Routes.GRAMMAR_DETAIL) { GrammarDetailScreen(onBack = { nav.popBackStack() }) }

        // Flashcard
        composable(Routes.FLASHCARD) {
            FlashcardModeScreen(onBack = { nav.popBackStack() }) { mode ->
                nav.navigate(Routes.flashcardLevel(mode.raw))
            }
        }
        composable(Routes.FLASHCARD_LEVEL) {
            FlashcardLevelScreen(
                onBack = { nav.popBackStack() },
                onOpenLevel = { mode, level -> nav.navigate(Routes.flashcardSession(mode.raw, level.id, level.jsonFile)) },
            )
        }
        composable(Routes.FLASHCARD_SESSION) { FlashcardSessionScreen(onBack = { nav.popBackStack() }) }

        // Hiragana / kana
        composable(Routes.HIRAGANA) {
            HiraganaScreen(
                onBack = { nav.popBackStack() },
                onStartFlashcard = { isKatakana -> nav.navigate(Routes.kanaFlashcard(isKatakana)) },
            )
        }
        composable(Routes.KANA_FLASHCARD) { KanaFlashcardScreen(onClose = { nav.popBackStack() }) }

        // Coming soon (Home "Lainnya" tile)
        composable(Routes.COMING_SOON) { entry ->
            ComingSoonScreen(
                feature = entry.arguments?.getString(Routes.Arg.FEATURE).orEmpty(),
                onBack = { nav.popBackStack() },
            )
        }
    }
}
