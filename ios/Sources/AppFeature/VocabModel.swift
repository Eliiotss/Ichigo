import SwiftUI
import Foundation

// MARK: - Vocabulary Item (format baru)
struct VocabularyItem: Identifiable, Codable, Hashable {
    let id: String
    let kanji: String
    let hiragana: String
    let arti: String
    let jenisKata: String
}

// MARK: - Vocabulary Level
struct VocabularyLevel: Identifiable {
    let id: String
    let name: String
    /// Subtitle shown under the level name, in the same shape as the kanji and
    /// grammar levels: an unlocked level opens with the exact number of entries
    /// in `jsonFile`, a locked level with an approximate "6.000+" figure.
    let description: String
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let vocabularyLevels: [VocabularyLevel] = [
    VocabularyLevel(id: "N5", name: "Beginner", description: "1.087 Kosakata Dasar", color: AppTheme.levelColor("N5"), bgColor: AppTheme.levelBackground("N5"), isLocked: false, jsonFile: "VocabN5"),
    VocabularyLevel(id: "N4", name: "Elementary", description: "1.015 Kosakata Dasar+", color: AppTheme.levelColor("N4"), bgColor: AppTheme.levelBackground("N4"), isLocked: false, jsonFile: "VocabN4"),
    VocabularyLevel(id: "N3", name: "Intermediate", description: "2.642 Kosakata Menengah", color: AppTheme.levelColor("N3"), bgColor: AppTheme.levelBackground("N3"), isLocked: false, jsonFile: "VocabN3"),
    VocabularyLevel(id: "N2", name: "Pre-Advanced", description: "2.122 Kosakata Lanjutan", color: AppTheme.levelColor("N2"), bgColor: AppTheme.levelBackground("N2"), isLocked: false, jsonFile: "VocabN2"),
    VocabularyLevel(id: "N1", name: "Advanced", description: "1.011 Kosakata Master", color: AppTheme.levelColor("N1"), bgColor: AppTheme.levelBackground("N1"), isLocked: false, jsonFile: "VocabN1")
]

// MARK: - Loader
enum VocabularyLoader {
    static func load(from filename: String) throws -> [VocabularyItem] {
        try ResourceLoader.loadArray(VocabularyItem.self, from: filename)
    }
}

