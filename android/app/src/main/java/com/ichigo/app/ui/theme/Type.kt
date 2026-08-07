package com.ichigo.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.ichigo.app.R

/**
 * Typography port of `AppTheme.rounded(size, weight)`.
 *
 * iOS uses SF Pro **Rounded** (`.system(design: .rounded)`); the design's stated
 * font is **Baloo 2**, bundled here as a variable font (`res/font/baloo2.ttf`).
 * Each weight is materialised from the single variable file via
 * [FontVariation] so `.medium`/`.bold`/`.heavy` render at the correct wght axis
 * on API 26+ (below that the default instance is used).
 *
 * Baloo 2 tops out at ExtraBold (800), so Swift's `.heavy` (800) and `.black`
 * (900) both map to [FontWeight.ExtraBold] — the roundest heaviest cut available.
 */
val Baloo2 = FontFamily(
    Font(R.font.baloo2, FontWeight.Normal, variationSettings = FontVariation.Settings(FontVariation.weight(400))),
    Font(R.font.baloo2, FontWeight.Medium, variationSettings = FontVariation.Settings(FontVariation.weight(500))),
    Font(R.font.baloo2, FontWeight.SemiBold, variationSettings = FontVariation.Settings(FontVariation.weight(600))),
    Font(R.font.baloo2, FontWeight.Bold, variationSettings = FontVariation.Settings(FontVariation.weight(700))),
    Font(R.font.baloo2, FontWeight.ExtraBold, variationSettings = FontVariation.Settings(FontVariation.weight(800))),
)

/**
 * Builds a rounded [TextStyle] the way Swift screens call `AppTheme.rounded(...)`.
 * `size` is a point value from the iOS source, applied as sp so it still respects
 * the user's system font scale on Android.
 */
fun rounded(size: Int, weight: FontWeight = FontWeight.Normal): TextStyle = TextStyle(
    fontFamily = Baloo2,
    fontWeight = weight,
    fontSize = size.sp,
)

// Weight aliases that read like the Swift call sites.
object Wt {
    val Regular = FontWeight.Normal
    val Medium = FontWeight.Medium
    val Semibold = FontWeight.SemiBold
    val Bold = FontWeight.Bold
    val Heavy = FontWeight.ExtraBold   // Baloo 2 max cut
    val Black = FontWeight.ExtraBold
}

/** Material3 typography so built-in components (TextField, Switch labels) are rounded too. */
val IchigoTypography = Typography().run {
    val f = Baloo2
    Typography(
        displayLarge = displayLarge.copy(fontFamily = f),
        displayMedium = displayMedium.copy(fontFamily = f),
        displaySmall = displaySmall.copy(fontFamily = f),
        headlineLarge = headlineLarge.copy(fontFamily = f),
        headlineMedium = headlineMedium.copy(fontFamily = f),
        headlineSmall = headlineSmall.copy(fontFamily = f),
        titleLarge = titleLarge.copy(fontFamily = f),
        titleMedium = titleMedium.copy(fontFamily = f),
        titleSmall = titleSmall.copy(fontFamily = f),
        bodyLarge = bodyLarge.copy(fontFamily = f),
        bodyMedium = bodyMedium.copy(fontFamily = f),
        bodySmall = bodySmall.copy(fontFamily = f),
        labelLarge = labelLarge.copy(fontFamily = f),
        labelMedium = labelMedium.copy(fontFamily = f),
        labelSmall = labelSmall.copy(fontFamily = f),
    )
}
