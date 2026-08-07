package com.ichigo.app.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.ichigo.app.ui.theme.Dimens
import com.ichigo.app.ui.theme.IchigoPalette
import com.ichigo.app.ui.theme.IchigoTheme
import com.ichigo.app.ui.theme.Wt
import com.ichigo.app.ui.theme.rounded
import com.ichigo.app.ui.theme.softShadow
import com.ichigo.app.util.LocalSpeech

/** A rounded surface card with the app's soft shadow (the common list/detail card). */
fun Modifier.ichigoCard(
    surface: Color,
    shadow: Color,
    radius: androidx.compose.ui.unit.Dp = Dimens.CardRadius,
    shadowRadius: androidx.compose.ui.unit.Dp = 9.dp,
    shadowY: androidx.compose.ui.unit.Dp = 6.dp,
): Modifier = this
    .softShadow(shadow, shadowRadius, radius, offsetY = shadowY)
    .clip(RoundedCornerShape(radius))
    .background(surface)

/** Pinned screen header with a circular back button + heavy title (Swift `ScreenHeader`). */
@Composable
fun ScreenHeader(title: String, onBack: () -> Unit) {
    val c = IchigoTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .softShadow(c.cardShadow, 6.dp, 22.dp, offsetY = 2.dp)
                .clip(CircleShape)
                .background(c.surface)
                .clickable(onClick = onBack),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.ChevronLeft, contentDescription = "Kembali", tint = c.primaryText)
        }
        Spacer(Modifier.width(14.dp))
        Text(
            title,
            style = rounded(24, Wt.Heavy),
            color = c.primaryText,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** Rounded pill search field (Swift `SearchField`). */
@Composable
fun SearchField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
) {
    val c = IchigoTheme.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(54.dp)
            .softShadow(c.cardShadow, 8.dp, 27.dp, offsetY = 3.dp)
            .clip(RoundedCornerShape(27.dp))
            .background(c.surface)
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Search, contentDescription = null, tint = c.secondaryText)
        Spacer(Modifier.width(12.dp))
        Box(Modifier.weight(1f)) {
            if (value.isEmpty()) {
                Text(placeholder, style = rounded(16, Wt.Medium), color = IchigoPalette.Placeholder)
            }
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                singleLine = true,
                textStyle = rounded(16, Wt.Medium).merge(TextStyle(color = c.primaryText)),
                cursorBrush = androidx.compose.ui.graphics.SolidColor(IchigoPalette.Accent),
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Search),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        if (value.isNotEmpty()) {
            Spacer(Modifier.width(8.dp))
            Icon(
                Icons.Filled.Cancel,
                contentDescription = "Hapus pencarian",
                tint = c.secondaryText,
                modifier = Modifier.size(18.dp).clip(CircleShape).clickable { onValueChange("") },
            )
        }
    }
}

/** Blue gradient hero card with two decorative circles (Swift `DetailHeroCard`). */
@Composable
fun DetailHeroCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .softShadow(IchigoPalette.Blue.copy(alpha = 0.28f), 16.dp, Dimens.HeroRadius, offsetY = 8.dp)
            .clip(RoundedCornerShape(Dimens.HeroRadius))
            .background(Brush.linearGradient(listOf(IchigoPalette.BlueLight, IchigoPalette.Blue)))
            .clipToBounds(),
    ) {
        // Decorative corner circles.
        Box(
            Modifier
                .size(190.dp)
                .offset(x = 230.dp, y = (-70).dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.12f)),
        )
        Box(
            Modifier
                .size(150.dp)
                .offset(x = (-60).dp, y = 120.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.10f)),
        )
        Box(Modifier.padding(20.dp)) { content() }
    }
}

/** Solid white badge over the hero card, e.g. "JLPT N5" (Swift `HeroBadge`). */
@Composable
fun HeroBadge(text: String) {
    Text(
        text,
        style = rounded(11, Wt.Bold),
        color = IchigoPalette.Blue,
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(Color.White)
            .padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

/** Translucent pill over the hero card (Swift `HeroPill`). */
@Composable
fun HeroPill(text: String) {
    Text(
        text,
        style = rounded(11, Wt.Semibold),
        color = Color.White,
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(Color.White.copy(alpha = 0.22f))
            .padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

/** Round translucent speak button over the hero card (Swift `HeroSpeakButton`). */
@Composable
fun HeroSpeakButton(text: String) {
    val speech = LocalSpeech.current
    Box(
        Modifier
            .size(38.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.22f))
            .clickable { speech.speak(text) },
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.AutoMirrored.Filled.VolumeUp, contentDescription = "Dengarkan pelafalan", tint = Color.White, modifier = Modifier.size(18.dp))
    }
}

/** White section card with a small gradient-tinted icon (Swift `DetailSectionCard`). */
@Composable
fun DetailSectionCard(
    title: String,
    icon: ImageVector,
    tint: Color = IchigoPalette.Blue,
    trailing: @Composable (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val c = IchigoTheme.colors
    Column(
        Modifier
            .fillMaxWidth()
            .ichigoCard(c.surface, c.cardShadow, shadowRadius = 8.dp, shadowY = 3.dp)
            .padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(30.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(tint.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(15.dp))
            }
            Spacer(Modifier.width(10.dp))
            Text(title, style = rounded(17, Wt.Bold), color = c.primaryText)
            Spacer(Modifier.weight(1f))
            if (trailing != null) trailing()
        }
        Spacer(Modifier.height(14.dp))
        content()
    }
}

/** Horizontally scrolling filter chips (Swift `FilterChipRow`). */
@Composable
fun FilterChipRow(filters: List<String>, selected: String, onSelect: (String) -> Unit) {
    val c = IchigoTheme.colors
    LazyRow(
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(filters) { filter ->
            val isSelected = filter == selected
            Box(
                Modifier
                    .height(46.dp)
                    .softShadow(c.cardShadow, 6.dp, 23.dp, offsetY = 2.dp)
                    .clip(RoundedCornerShape(23.dp))
                    .background(if (isSelected) IchigoPalette.Accent else c.surface)
                    .clickable { onSelect(filter) }
                    .padding(horizontal = 22.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    filter,
                    style = rounded(15, Wt.Bold),
                    color = if (isSelected) Color.White else c.secondaryText,
                )
            }
        }
    }
}

/** Sun/moon slide toggle for the theme (Swift `ThemeSlideToggle`). */
@Composable
fun ThemeSlideToggle(isDark: Boolean, onToggle: (Boolean) -> Unit) {
    val trackWidth = 78.dp
    val trackHeight = 40.dp
    val knobSize = 32.dp
    val inset = 4.dp
    val travel = (trackWidth - knobSize) / 2 - inset
    val offsetX by animateDpAsState(if (isDark) travel else -travel, spring(dampingRatio = 0.72f, stiffness = 900f), label = "knob")

    Box(
        Modifier
            .size(trackWidth, trackHeight)
            .clip(RoundedCornerShape(50))
            .background(
                Brush.horizontalGradient(
                    if (isDark) listOf(IchigoPalette.IndigoDeep, IchigoPalette.Navy)
                    else listOf(IchigoPalette.BlueLight, IchigoPalette.Blue),
                ),
            )
            .clickable { onToggle(!isDark) },
        contentAlignment = Alignment.Center,
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 11.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.LightMode, null, tint = Color.White.copy(alpha = if (isDark) 0.45f else 0f), modifier = Modifier.size(15.dp))
            Icon(Icons.Filled.DarkMode, null, tint = Color.White.copy(alpha = if (isDark) 0f else 0.5f), modifier = Modifier.size(15.dp))
        }
        Box(
            Modifier
                .offset(x = offsetX)
                .size(knobSize)
                .clip(CircleShape)
                .background(Color.White),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                if (isDark) Icons.Filled.DarkMode else Icons.Filled.LightMode,
                contentDescription = "Mode tampilan",
                tint = if (isDark) IchigoPalette.IndigoDeep else IchigoPalette.Caution,
                modifier = Modifier.size(16.dp),
            )
        }
    }
}

/** Empty/error/loading states (Swift `EmptyStateView` / `ErrorStateView`). */
@Composable
fun EmptyState(title: String, subtitle: String, icon: ImageVector = Icons.Filled.Inbox, modifier: Modifier = Modifier) {
    val c = IchigoTheme.colors
    Column(
        modifier = modifier.padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(icon, null, tint = c.secondaryText, modifier = Modifier.size(42.dp))
        Text(title, style = rounded(16, Wt.Bold), color = c.primaryText)
        Text(subtitle, style = rounded(13), color = c.secondaryText, textAlign = TextAlign.Center)
    }
}

@Composable
fun ErrorState(message: String, modifier: Modifier = Modifier) =
    EmptyState("Gagal memuat data", message, Icons.Filled.Warning, modifier)
