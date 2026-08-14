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
    // N5 vocab tops up Android-first (counters, dates, everyday nouns/loanwords);
    // iOS/web still at 905 until the later sync pass. Keep equal to VocabN5.json.
    ContentLevel("N5", "Beginner", "1.087 Kosakata Dasar", false, "VocabN5"),
    // N4 vocab expanded Android-first (Tango N4 coverage guide, original glosses);
    // iOS/web still at 700 until the later sync pass. Keep equal to VocabN4.json.
    ContentLevel("N4", "Elementary", "1.027 Kosakata Dasar", false, "VocabN4"),
    // N3 vocab expanded Android-first (Tango N3 coverage guide, original glosses);
    // iOS/web still at 1.800 until the later sync pass. Keep equal to VocabN3.json.
    ContentLevel("N3", "Intermediate", "2.651 Kosakata Menengah", false, "VocabN3"),
    // N2 vocab expanded Android-first (Tango N2 coverage guide, original glosses);
    // iOS/web still at 1.447 until the later sync pass. Keep equal to VocabN2.json.
    ContentLevel("N2", "Pre-Advanced", "2.122 Kosakata Lanjutan", false, "VocabN2"),
    // N1 vocabulary ships Android-first as a growing, verified batch (see
    // assets/data/VocabN1.json); iOS/web catch up later. Kanji/Grammar N1 have no
    // dataset yet and stay locked. Keep this count equal to VocabN1.json's length.
    ContentLevel("N1", "Advanced", "304 Kosakata Master", false, "VocabN1"),
)

/** Mirrors `grammarLevels` in GrammarModel.swift. */
val grammarLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "84 Pola Tata Bahasa Dasar", false, "GrammarN5"),
    ContentLevel("N4", "Elementary", "132 Pola Tata Bahasa Dasar+", false, "GrammarN4"),
    ContentLevel("N3", "Intermediate", "182 Pola Tata Bahasa Menengah", false, "GrammarN3"),
    ContentLevel("N2", "Pre-Advanced", "141 Pola Tata Bahasa Lanjutan", false, "GrammarN2"),
    ContentLevel("N1", "Advanced", "Pola Tata Bahasa Master", true, "GrammarN1"),
)
