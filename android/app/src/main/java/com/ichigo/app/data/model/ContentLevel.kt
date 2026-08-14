package com.ichigo.app.data.model

import androidx.compose.ui.graphics.Color
import com.ichigo.app.ui.theme.IchigoPalette

/**
 * Unifies the three near-identical Swift level configs (`JLPTLevel`,
 * `VocabularyLevel`, `GrammarLevel`) into one type. In Swift each carried a
 * SwiftUI `Color`; here the colour is derived from the id via
 * [IchigoPalette.levelColor] so no colour is stored in data — identical result,
 * one source of truth.
 *
 * The `description` strings are copied verbatim from the Swift level arrays so
 * every subtitle ("120 Essential Kanji", "84 Pola Tata Bahasa Dasar", ...)
 * matches the iOS app exactly.
 */
data class ContentLevel(
    val id: String,
    val name: String,
    val description: String,
    val isLocked: Boolean,
    val jsonFile: String,
) {
    val color: Color get() = IchigoPalette.levelColor(id)
    val bgColor: Color get() = IchigoPalette.levelBackground(id)
}

/** Mirrors `jlptLevels` in KanjiModel.swift. */
val kanjiLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "120 Essential Kanji", false, "KanjiN5"),
    ContentLevel("N4", "Elementary", "181 Essential Kanji", false, "KanjiN4"),
    ContentLevel("N3", "Intermediate", "367 Essential Kanji", false, "KanjiN3"),
    ContentLevel("N2", "Pre-Advanced", "247 Complex Kanji", false, "KanjiN2"),
    ContentLevel("N1", "Advanced", "2.000+ Master Kanji", true, "KanjiN1"),
)

/** Mirrors `vocabularyLevels` in VocabModel.swift. */
val vocabularyLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "905 Kosakata Dasar", false, "VocabN5"),
    ContentLevel("N4", "Elementary", "700 Kosakata Dasar+", false, "VocabN4"),
    ContentLevel("N3", "Intermediate", "1.800 Kosakata Menengah", false, "VocabN3"),
    ContentLevel("N2", "Pre-Advanced", "1.447 Kosakata Lanjutan", false, "VocabN2"),
    ContentLevel("N1", "Advanced", "10.000+ Kosakata Master", true, "VocabN1"),
)

/** Mirrors `grammarLevels` in GrammarModel.swift. */
val grammarLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "84 Pola Tata Bahasa Dasar", false, "GrammarN5"),
    ContentLevel("N4", "Elementary", "132 Pola Tata Bahasa Dasar+", false, "GrammarN4"),
    ContentLevel("N3", "Intermediate", "182 Pola Tata Bahasa Menengah", false, "GrammarN3"),
    ContentLevel("N2", "Pre-Advanced", "141 Pola Tata Bahasa Lanjutan", false, "GrammarN2"),
    ContentLevel("N1", "Advanced", "Pola Tata Bahasa Master", true, "GrammarN1"),
)
