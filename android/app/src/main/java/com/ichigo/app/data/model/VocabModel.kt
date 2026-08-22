package com.ichigo.app.data.model

import kotlinx.serialization.Serializable

/**
 * Port of `VocabModel.swift`'s `VocabularyItem` (new format). Same field names as
 * the Swift struct and the VocabN5/N4/N3.json keys.
 */
@Serializable
data class VocabularyItem(
    val id: String = "",
    val kanji: String = "",
    val hiragana: String = "",
    val arti: String = "",
    val jenisKata: String = "",
)
