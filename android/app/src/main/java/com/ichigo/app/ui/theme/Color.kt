package com.ichigo.app.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Direct port of `AppTheme.swift` — the single source of truth for every colour,
 * radius and gradient in the app. Values are copied verbatim from the iOS
 * `AppTheme` enum (hex literals unchanged) so the Android UI is pixel-identical.
 *
 * Split in two:
 *  - [IchigoPalette]: scheme-independent brand colours (blue accent, level scale,
 *    tile gradients, semantic colours). Equivalent to the raw `static let`s and
 *    the `levelColor` / `tileGradient` functions in Swift.
 *  - [IchigoColors]: the scheme-dependent surfaces/text, equivalent to the
 *    `screenBackground(scheme)` / `surface(scheme)` / ... derived functions.
 */
object IchigoPalette {
    // MARK: 1. Backgrounds & surfaces (raw values)
    val PageLight = Color(0xFFFFFFFF)
    val CardLight = Color(0xFFFFFFFF)
    // Light-grey fill for inner "soft" boxes (example sentences, usage points) so
    // they still read on a white page + white cards.
    val SoftSurfaceLight = Color(0xFFF1F2F4)
    val Track = Color(0xFFE4DAD1)
    val TabBarLight = Color(0xFFFBF6F3)
    val Hairline = Color(0xFFEAE1DA)
    val PageDark = Color(0xFF12161F)
    val CardDark = Color(0xFF1C2231)

    // MARK: 2. Text
    val Ink = Color(0xFF2B2029)
    val Muted = Color(0xFFB0A199)
    val Placeholder = Color(0xFFC4B8B1)

    // MARK: 3. Blue accent & gradient scale
    val Blue = Color(0xFF2E7BFF)
    val BlueLight = Color(0xFF4F97FF)
    val BlueDeep = Color(0xFF1F63DB)
    val Indigo = Color(0xFF6E7BFF)
    val IndigoDeep = Color(0xFF4A55E8)
    val IndigoSoft = Color(0xFF7C93FF)
    val Navy = Color(0xFF3A45C4)
    val Sky = Color(0xFF29B6F0)
    val SkyDeep = Color(0xFF0E90D6)
    val Teal = Color(0xFF22C9DE)
    val TealDeep = Color(0xFF0FA8BE)
    val Violet = Color(0xFF9A8BFF)
    val VioletDeep = Color(0xFF6E5CF0)

    /** Short name for the main accent (= [Blue]). */
    val Accent = Blue

    /** Sea-blue tone for reading captions (on'yomi/kun'yomi, word type). */
    val Ocean = SkyDeep

    /** Main blue gradient — home hero card, avatar, primary buttons. */
    val AccentGradient = listOf(BlueLight, Blue)

    // MARK: 6. Meaning colours (correct / wrong / streak)
    val Danger = Color(0xFFFF3B30)
    val DangerSoft = Color(0xFFFF7A70)
    val Caution = Color(0xFFFF9500)
    val Success = Color(0xFF22B981)

    /** Primary colour of a JLPT level (N5 youngest → N1 deepest). */
    fun levelColor(id: String): Color = when (id) {
        "N5" -> BlueLight
        "N4" -> Blue
        "N3" -> Sky
        "N2" -> Indigo
        "N1" -> IndigoDeep
        else -> Blue
    }

    /** Translucent chip background for a level (15% of its colour). */
    fun levelBackground(id: String): Color = levelColor(id).copy(alpha = 0.15f)

    /** Gradient for a home menu tile, keyed by the tile id. */
    fun tileGradient(id: String): List<Color> = when (id) {
        "huruf" -> listOf(BlueLight, Blue)
        "kanji" -> listOf(Indigo, IndigoDeep)
        "flashcard" -> listOf(Sky, SkyDeep)
        "vocabulary" -> listOf(Teal, TealDeep)
        "grammar" -> listOf(Violet, VioletDeep)
        else -> listOf(IndigoSoft, IndigoDeep)
    }
}

/**
 * Scheme-dependent colours, provided through [LocalIchigoColors]. Mirrors the
 * `AppTheme.xxx(scheme)` helper functions. `primaryText`/`secondaryText` use the
 * ink/muted palette in light mode and near-white/grey in dark mode, matching the
 * Swift `.primary`/`.secondary` behaviour.
 */
@Immutable
data class IchigoColors(
    val isDark: Boolean,
    val page: Color,
    val surface: Color,
    val softSurface: Color,
    val primaryText: Color,
    val secondaryText: Color,
    val track: Color,
    val tabBar: Color,
    val hairline: Color,
    val cardShadow: Color,
) {
    /** Soft tint of a colour for count pills / stat chips (10% light, 20% dark). */
    fun softTint(color: Color): Color = color.copy(alpha = if (isDark) 0.20f else 0.10f)
}

val LightIchigoColors = IchigoColors(
    isDark = false,
    page = IchigoPalette.PageLight,
    surface = IchigoPalette.CardLight,
    softSurface = IchigoPalette.SoftSurfaceLight,
    primaryText = IchigoPalette.Ink,
    secondaryText = IchigoPalette.Muted,
    track = IchigoPalette.Track,
    tabBar = IchigoPalette.TabBarLight,
    hairline = IchigoPalette.Hairline,
    cardShadow = IchigoPalette.Ink.copy(alpha = 0.08f),
)

val DarkIchigoColors = IchigoColors(
    isDark = true,
    page = IchigoPalette.PageDark,
    surface = IchigoPalette.CardDark,
    softSurface = Color.White.copy(alpha = 0.06f),
    // In dark mode Swift falls back to .primary/.secondary (near-white/grey).
    primaryText = Color(0xFFF2F3F7),
    secondaryText = Color(0xFF9BA1B0),
    track = Color.White.copy(alpha = 0.15f),
    tabBar = IchigoPalette.CardDark,
    hairline = Color.White.copy(alpha = 0.08f),
    cardShadow = Color.Black.copy(alpha = 0.35f),
)

val LocalIchigoColors = staticCompositionLocalOf { LightIchigoColors }
