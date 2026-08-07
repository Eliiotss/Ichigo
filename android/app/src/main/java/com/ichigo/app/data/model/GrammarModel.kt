package com.ichigo.app.data.model

import kotlinx.serialization.Serializable

/**
 * Port of `GrammarModel.swift`. The Swift `init(from:)` supplies defaults for
 * every optional/missing field; the Kotlin equivalent is default property values
 * combined with `coerceInputValues = true` on the [com.ichigo.app.data.resource]
 * Json instance, which turns a present-but-null JSON value into the default,
 * matching Swift's `decodeIfPresent(...) ?? default`.
 */
@Serializable
data class GrammarItem(
    val id: String = "",
    val pattern: String = "",
    val romaji: String = "",
    val meaning: String = "",
    val level: String = "N4",
    val difficulty: Int = 3,
    val structure: String = "",
    val tags: List<String> = emptyList(),
    val treeCategory: String = "Grammar",
    val relatedGrammarIds: List<String> = emptyList(),
    val nuance: String = "Common",
    val frequency: String = "Common",
    val commonMistakes: List<String> = emptyList(),
    val explanation: String = "",
    val usage: List<String> = emptyList(),
    val examples: List<GrammarExample> = emptyList(),
    val bunpouPersamaan: List<String> = emptyList(),
)

@Serializable
data class GrammarExample(
    val japanese: String = "",
    val romaji: String = "",
    val translation: String = "",
)
