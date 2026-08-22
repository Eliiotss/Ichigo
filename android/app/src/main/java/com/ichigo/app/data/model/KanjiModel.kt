package com.ichigo.app.data.model

import kotlinx.serialization.Serializable

/**
 * Port of `KanjiModel.swift`. Property names are kept identical to the Swift
 * structs (and therefore to the JSON keys in KanjiN5/N4/N3.json) so the exact
 * same dataset files decode unchanged.
 */
@Serializable
data class KanjiItem(
    val id: String = "",
    val kanji: String = "",
    val onyomi: String = "",
    val kunyomi: String = "",
    val romaji: String = "",
    val meaning: String = "",
    val examples: List<KanjiExample> = emptyList(),
)

@Serializable
data class KanjiExample(
    val word: String = "",
    val reading: String = "",
    val romaji: String = "",
    val meaning: String = "",
    val sentence: String? = null,
    val sentenceFurigana: String? = null,
    val sentenceMeaning: String? = null,
)
