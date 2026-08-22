package com.ichigo.app.data.model

import kotlinx.serialization.Serializable

/** JSON shapes for Hiragana.json (both scripts live in one file). */
@Serializable
data class KanaItemJSON(
    val kana: String = "",
    val romaji: String = "",
)

@Serializable
data class KanaGroupJSON(
    val title: String = "",
    val subtitle: String = "",
    val columns: List<String> = emptyList(),
    val rows: List<List<KanaItemJSON?>> = emptyList(),
)

/** Runtime kana cell. Identity is the kana glyph itself, as in Swift. */
data class KanaItem(
    val kana: String,
    val romaji: String,
)

/** Runtime kana table: a grid of optional cells plus its column headers. */
data class KanaGroup(
    val title: String,
    val subtitle: String,
    val items: List<List<KanaItem?>>,
    val columns: List<String>,
) {
    /**
     * Classifies a group by the Unicode block of its characters, exactly like the
     * Swift `isKatakanaScript` extension. The dataset ships hiragana and katakana
     * in one file, so this routes each group to the correct tab.
     */
    val isKatakanaScript: Boolean
        get() {
            for (row in items) {
                for (item in row) {
                    val value = item?.kana?.firstOrNull()?.code ?: continue
                    if (value in 0x30A0..0x30FF) return true   // Katakana block
                    if (value in 0x3040..0x309F) return false  // Hiragana block
                }
            }
            return false
        }
}
