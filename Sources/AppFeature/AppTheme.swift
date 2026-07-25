import SwiftUI

/// Design tokens taken from the Ichigo v2 design.
///
/// The palette is warm-beige with a blue accent: a soft `#E7E0DC` page, white
/// cards with generous corner radii, deep plum text and muted taupe secondary
/// text. Accent gradients run from a light to a deep blue. Semantic colours
/// (correct/wrong, grade buttons, destructive actions) stay outside the palette.
enum AppTheme {

    // MARK: - Core palette (design hex values)
    static let pageLight = Color(hex: 0xE7E0DC)      // warm beige page
    static let cardLight = Color.white
    static let ink = Color(hex: 0x2B2029)            // primary text
    static let muted = Color(hex: 0xB0A199)          // secondary text
    static let placeholder = Color(hex: 0xC4B8B1)
    static let track = Color(hex: 0xF0E7E2)          // progress track
    static let tabBarLight = Color(hex: 0xFBF6F3)
    static let hairline = Color(hex: 0xEFE6E0)

    static let blue = Color(hex: 0x2E7BFF)           // accent
    static let blueLight = Color(hex: 0x4F97FF)
    static let blueDeep = Color(hex: 0x1F63DB)
    static let indigo = Color(hex: 0x6E7BFF)
    static let indigoDeep = Color(hex: 0x4A55E8)
    static let sky = Color(hex: 0x29B6F0)
    static let skyDeep = Color(hex: 0x0E90D6)
    static let teal = Color(hex: 0x22C9DE)
    static let tealDeep = Color(hex: 0x0FA8BE)
    static let violet = Color(hex: 0x9A8BFF)
    static let violetDeep = Color(hex: 0x6E5CF0)

    static let accent = blue

    /// Primary blue gradient used by the hero card, avatar and primary buttons.
    static let accentGradient = LinearGradient(
        colors: [blueLight, blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Surfaces
    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.systemBackground) : pageLight
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : cardLight
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .primary : ink
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .secondary : muted
    }

    static func trackColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.15) : track
    }

    /// Soft card shadow — `0 6px 18px rgba(43,32,41,.06)` in the design.
    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.3) : Color(hex: 0x2B2029).opacity(0.06)
    }

    static func softShadow(_ scheme: ColorScheme) -> Color { cardShadow(scheme) }

    // MARK: - Typography
    /// The design uses Baloo 2 / Nunito; SF Pro Rounded is the native equivalent.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Metrics
    static let cardRadius: CGFloat = 22
    static let heroRadius: CGFloat = 26
    static let tileIconRadius: CGFloat = 15

    // MARK: - JLPT level scale (N5 light → N1 deep)
    static func levelColor(_ id: String) -> Color {
        switch id {
        case "N5": return blueLight
        case "N4": return blue
        case "N3": return sky
        case "N2": return indigo
        case "N1": return indigoDeep
        default:   return blue
        }
    }

    static func levelBackground(_ id: String) -> Color {
        levelColor(id).opacity(0.15)
    }

    // MARK: - Home menu tile gradients (exact design values)
    static func tileGradient(_ id: String) -> [Color] {
        switch id {
        case "huruf":      return [blueLight, blue]
        case "kanji":      return [indigo, indigoDeep]
        case "flashcard":  return [sky, skyDeep]
        case "vocabulary": return [teal, tealDeep]
        case "grammar":    return [violet, violetDeep]
        default:           return [Color(hex: 0x7C93FF), indigoDeep]
        }
    }

    /// Ocean tone kept for reading annotations (on'yomi / kun'yomi, word types).
    static let ocean = skyDeep
}

extension Color {
    /// Builds a colour from a 0xRRGGBB literal so design hex values stay readable.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
