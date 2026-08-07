package com.ichigo.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Faithful soft drop shadow — the Kotlin equivalent of SwiftUI's
 * `.shadow(color:radius:x:y:)`. Compose's built-in `Modifier.shadow` is
 * elevation-based and tints ambient/spot colours differently across API levels,
 * so it can't reproduce the exact coloured blur the iOS cards use. This draws a
 * blurred rounded rectangle behind the content using the platform
 * `setShadowLayer`, so a card with `cardShadow`, radius 9, y 6 looks the same as
 * on iOS.
 *
 * @param color  shadow colour (already includes its alpha, like `cardShadow`)
 * @param radius blur radius, matching the SwiftUI `radius:` argument
 * @param cornerRadius corner radius of the shadowed shape
 * @param offsetX/offsetY shadow offset, matching SwiftUI `x:`/`y:`
 */
fun Modifier.softShadow(
    color: Color,
    radius: Dp,
    cornerRadius: Dp,
    offsetX: Dp = 0.dp,
    offsetY: Dp = 0.dp,
): Modifier = this.drawBehind {
    if (color.alpha == 0f || radius.toPx() <= 0f) return@drawBehind
    val cr = cornerRadius.toPx()
    drawIntoCanvas { canvas ->
        val paint = Paint()
        val frameworkPaint = paint.asFrameworkPaint()
        frameworkPaint.color = android.graphics.Color.TRANSPARENT
        frameworkPaint.setShadowLayer(
            radius.toPx(),
            offsetX.toPx(),
            offsetY.toPx(),
            color.toArgb(),
        )
        canvas.drawRoundRect(
            left = 0f,
            top = 0f,
            right = size.width,
            bottom = size.height,
            radiusX = cr,
            radiusY = cr,
            paint = paint,
        )
    }
}

/** Convenience for the common card shadow used across list/detail screens. */
fun Modifier.cardShadow(
    color: Color,
    radius: Dp = 9.dp,
    cornerRadius: Dp = Dimens.CardRadius,
    offsetY: Dp = 6.dp,
): Modifier = softShadow(color, radius, cornerRadius, 0.dp, offsetY)

/** A rounded rectangle shape shortcut mirroring `.continuous` corners. */
fun roundedShape(radius: Dp): Shape = RoundedCornerShape(radius)
