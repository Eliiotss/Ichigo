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

/**
 * Mirrors `jlptLevels` in KanjiModel.swift. Kanji counts grow Android-first as
 * characters from the study material (materials/materi.md) that were missing from
 * the original curated sets are added at their proper JLPT level (original
 * on/kun/meaning + five verified compound examples each); iOS/web catch up in the
 * later sync pass. Duplicate kanji entries — both within a level and the same
 * character repeated across levels — were removed, keeping each kanji only at its
 * most basic (lowest) level. Keep each count equal to the matching KanjiN*.json length.
 */
val kanjiLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "142 Essential Kanji", false, "KanjiN5"),
    ContentLevel("N4", "Elementary", "269 Essential Kanji", false, "KanjiN4"),
    ContentLevel("N3", "Intermediate", "594 Essential Kanji", false, "KanjiN3"),
    ContentLevel("N2", "Pre-Advanced", "612 Complex Kanji", false, "KanjiN2"),
    // N1 Kanji is now unlocked: KanjiN1.json ships a substantial verified set of
    // advanced/master kanji from the study material (Android-first, still growing
    // as the remaining tail is added). Keep this count equal to KanjiN1.json.
    ContentLevel("N1", "Advanced", "305 Master Kanji", false, "KanjiN1"),
)

/** Mirrors `vocabularyLevels` in VocabModel.swift. */
val vocabularyLevels: List<ContentLevel> = listOf(
    // N5 vocab tops up Android-first (counters, dates, everyday nouns/loanwords);
    // iOS/web still at 905 until the later sync pass. Keep equal to VocabN5.json.
    ContentLevel("N5", "Beginner", "1.087 Kosakata Dasar", false, "VocabN5"),
    // N4 vocab expanded Android-first (Tango N4 coverage guide, original glosses);
    // iOS/web still at 700 until the later sync pass. Keep equal to VocabN4.json.
    ContentLevel("N4", "Elementary", "1.015 Kosakata Dasar", false, "VocabN4"),
    // N3 vocab expanded Android-first (Tango N3 coverage guide, original glosses);
    // iOS/web still at 1.800 until the later sync pass. Keep equal to VocabN3.json.
    ContentLevel("N3", "Intermediate", "2.642 Kosakata Menengah", false, "VocabN3"),
    // N2 vocab expanded Android-first (Tango N2 coverage guide, original glosses);
    // iOS/web still at 1.447 until the later sync pass. Keep equal to VocabN2.json.
    ContentLevel("N2", "Pre-Advanced", "2.122 Kosakata Lanjutan", false, "VocabN2"),
    // N1 vocabulary ships Android-first as a growing, verified batch (see
    // assets/data/VocabN1.json); iOS/web catch up later. Kanji/Grammar N1 have no
    // dataset yet and stay locked. Keep this count equal to VocabN1.json's length.
    ContentLevel("N1", "Advanced", "1.011 Kosakata Master", false, "VocabN1"),
)

/** Mirrors `grammarLevels` in GrammarModel.swift. */
val grammarLevels: List<ContentLevel> = listOf(
    ContentLevel("N5", "Beginner", "87 Pola Tata Bahasa Dasar", false, "GrammarN5"),
    ContentLevel("N4", "Elementary", "137 Pola Tata Bahasa Dasar+", false, "GrammarN4"),
    ContentLevel("N3", "Intermediate", "191 Pola Tata Bahasa Menengah", false, "GrammarN3"),
    ContentLevel("N2", "Pre-Advanced", "155 Pola Tata Bahasa Lanjutan", false, "GrammarN2"),
    // N1 Grammar ships Android-first as a growing, verified set (original
    // explanations + example sentences; pattern names taken as a checklist from
    // materials/grammar.md). Keep this count equal to GrammarN1.json's length.
    ContentLevel("N1", "Advanced", "104 Pola Tata Bahasa Master", false, "GrammarN1"),
)
