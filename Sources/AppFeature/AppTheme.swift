import SwiftUI

/// Centralised, blue-dominant colour palette for the app.
///
/// The whole UI is built from an analogous blue family (sky → blue → ocean →
/// indigo → navy, plus teal and cyan) so the chrome reads as one cohesive theme
/// instead of clashing. Semantic status colours (grade buttons, streak, success,
/// error) intentionally live outside this palette because they communicate
/// meaning rather than branding.
enum AppTheme {
    // MARK: - Blue family
    static let sky = Color(red: 0.29, green: 0.63, blue: 1.00)
    static let blue = Color(red: 0.11, green: 0.49, blue: 0.96)
    static let ocean = Color(red: 0.07, green: 0.40, blue: 0.85)
    static let indigo = Color(red: 0.31, green: 0.33, blue: 0.79)
    static let navy = Color(red: 0.16, green: 0.25, blue: 0.60)
    static let teal = Color(red: 0.10, green: 0.56, blue: 0.75)
    static let cyan = Color(red: 0.19, green: 0.70, blue: 0.92)
    static let slate = Color(red: 0.36, green: 0.42, blue: 0.55)

    /// Primary brand / accent colour.
    static let accent = blue

    // MARK: - JLPT level scale (N5 light → N1 deep)
    static func levelColor(_ id: String) -> Color {
        switch id {
        case "N5": return sky
        case "N4": return blue
        case "N3": return ocean
        case "N2": return indigo
        case "N1": return navy
        default:   return blue
        }
    }

    static func levelBackground(_ id: String) -> Color {
        levelColor(id).opacity(0.15)
    }

    // MARK: - Home menu tile gradients (distinct hues, all within the blue family)
    static func tileGradient(_ id: String) -> [Color] {
        switch id {
        case "huruf":      return [cyan, blue]
        case "kanji":      return [indigo, navy]
        case "flashcard":  return [sky, blue]
        case "vocabulary": return [teal, ocean]
        case "grammar":    return [blue, indigo]
        default:           return [slate, navy]
        }
    }
}
