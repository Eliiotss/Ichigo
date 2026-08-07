package com.ichigo.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.ichigo.app.data.model.AppAppearance

/**
 * Accessor object, used like `MaterialTheme.colorScheme` — call
 * `IchigoTheme.colors` inside composables to read the current scheme-dependent
 * palette (the Kotlin equivalent of passing `colorScheme` around SwiftUI views).
 */
object IchigoTheme {
    val colors: IchigoColors
        @Composable @ReadOnlyComposable get() = LocalIchigoColors.current
}

private fun materialLight() = lightColorScheme(
    primary = IchigoPalette.Blue,
    onPrimary = Color.White,
    secondary = IchigoPalette.Indigo,
    background = IchigoPalette.PageLight,
    onBackground = IchigoPalette.Ink,
    surface = IchigoPalette.CardLight,
    onSurface = IchigoPalette.Ink,
    surfaceVariant = IchigoPalette.PageLight,
    onSurfaceVariant = IchigoPalette.Muted,
    error = IchigoPalette.Danger,
    outline = IchigoPalette.Hairline,
)

private fun materialDark() = darkColorScheme(
    primary = IchigoPalette.Blue,
    onPrimary = Color.White,
    secondary = IchigoPalette.Indigo,
    background = IchigoPalette.PageDark,
    onBackground = Color(0xFFF2F3F7),
    surface = IchigoPalette.CardDark,
    onSurface = Color(0xFFF2F3F7),
    surfaceVariant = IchigoPalette.CardDark,
    onSurfaceVariant = Color(0xFF9BA1B0),
    error = IchigoPalette.Danger,
    outline = Color.White.copy(alpha = 0.12f),
)

/**
 * Root theme wrapper (mirrors `RootView.preferredColorScheme(appearance)`).
 * Resolves [appearance] against the system setting, publishes [IchigoColors] via
 * [LocalIchigoColors], and installs a Material3 theme so built-in controls adopt
 * the blue accent and rounded type.
 */
@Composable
fun IchigoTheme(
    appearance: AppAppearance,
    content: @Composable () -> Unit,
) {
    val systemDark = isSystemInDarkTheme()
    val dark = when (appearance) {
        AppAppearance.SYSTEM -> systemDark
        AppAppearance.LIGHT -> false
        AppAppearance.DARK -> true
    }

    val colors = if (dark) DarkIchigoColors else LightIchigoColors
    val material = if (dark) materialDark() else materialLight()

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // Transparent bars; icon contrast follows the effective scheme.
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !dark
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !dark
        }
    }

    CompositionLocalProvider(LocalIchigoColors provides colors) {
        MaterialTheme(
            colorScheme = material,
            typography = IchigoTypography,
            content = content,
        )
    }
}
