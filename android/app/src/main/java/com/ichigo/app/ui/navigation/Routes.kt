package com.ichigo.app.ui.navigation

/**
 * Central route table. Mirrors the iOS navigation graph: three tabs (Home /
 * Profile / Settings) with the browsing + flashcard screens pushed on top of the
 * Home tab, exactly as the SwiftUI `NavigationStack` inside the Home `TabView`.
 */
object Routes {
    const val SPLASH = "splash"

    // Bottom-tab roots
    const val HOME = "home"
    const val PROFILE = "profile"
    const val SETTINGS = "settings"

    // Home-stack pushes
    const val KANJI = "kanji"
    const val VOCAB = "vocab"
    const val GRAMMAR = "grammar"
    const val FLASHCARD = "flashcard"
    const val HIRAGANA = "hiragana"

    const val KANJI_LIST = "kanji/list/{jsonFile}/{levelId}"
    const val KANJI_DETAIL = "kanji/detail/{jsonFile}/{levelId}/{itemId}"
    const val VOCAB_LIST = "vocab/list/{jsonFile}/{levelId}"
    const val GRAMMAR_LIST = "grammar/list/{jsonFile}/{levelId}"
    const val GRAMMAR_DETAIL = "grammar/detail/{jsonFile}/{levelId}/{itemId}"

    const val FLASHCARD_LEVEL = "flashcard/level/{mode}"
    const val FLASHCARD_SESSION = "flashcard/session/{mode}/{levelId}/{jsonFile}"
    const val KANA_FLASHCARD = "hiragana/flashcard/{isKatakana}"
    const val COMING_SOON = "coming/{feature}"

    fun kanjiList(jsonFile: String, levelId: String) = "kanji/list/$jsonFile/$levelId"
    fun kanjiDetail(jsonFile: String, levelId: String, itemId: String) = "kanji/detail/$jsonFile/$levelId/$itemId"
    fun vocabList(jsonFile: String, levelId: String) = "vocab/list/$jsonFile/$levelId"
    fun grammarList(jsonFile: String, levelId: String) = "grammar/list/$jsonFile/$levelId"
    fun grammarDetail(jsonFile: String, levelId: String, itemId: String) = "grammar/detail/$jsonFile/$levelId/$itemId"
    fun flashcardLevel(mode: String) = "flashcard/level/$mode"
    fun flashcardSession(mode: String, levelId: String, jsonFile: String) = "flashcard/session/$mode/$levelId/$jsonFile"
    fun kanaFlashcard(isKatakana: Boolean) = "hiragana/flashcard/$isKatakana"
    fun comingSoon(feature: String) = "coming/$feature"

    object Arg {
        const val JSON_FILE = "jsonFile"
        const val LEVEL_ID = "levelId"
        const val ITEM_ID = "itemId"
        const val MODE = "mode"
        const val IS_KATAKANA = "isKatakana"
        const val FEATURE = "feature"
    }
}
