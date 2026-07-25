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
    let description: String
    /// Number of words in the bundled dataset. Locked levels carry 0 because
    /// their dataset has not shipped yet; the card only shows a non-zero count.
    let totalWords: Int
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let vocabularyLevels: [VocabularyLevel] = [
    VocabularyLevel(id: "N5", name: "Beginner", description: "Kosakata Dasar", totalWords: 800, color: AppTheme.levelColor("N5"), bgColor: AppTheme.levelBackground("N5"), isLocked: false, jsonFile: "VocabN5"),
    VocabularyLevel(id: "N4", name: "Elementary", description: "Kosakata Dasar+", totalWords: 700, color: AppTheme.levelColor("N4"), bgColor: AppTheme.levelBackground("N4"), isLocked: false, jsonFile: "VocabN4"),
    VocabularyLevel(id: "N3", name: "Intermediate", description: "Kosakata Menengah", totalWords: 1110, color: AppTheme.levelColor("N3"), bgColor: AppTheme.levelBackground("N3"), isLocked: false, jsonFile: "VocabN3"),
    VocabularyLevel(id: "N2", name: "Pre-Advanced", description: "Kosakata Lanjutan", totalWords: 0, color: AppTheme.levelColor("N2"), bgColor: AppTheme.levelBackground("N2"), isLocked: true, jsonFile: "VocabN2"),
    VocabularyLevel(id: "N1", name: "Advanced", description: "Kosakata Master", totalWords: 0, color: AppTheme.levelColor("N1"), bgColor: AppTheme.levelBackground("N1"), isLocked: true, jsonFile: "VocabN1")
]

// MARK: - Loader
enum VocabularyLoader {
    static func load(from filename: String) throws -> [VocabularyItem] {
        try ResourceLoader.loadArray(VocabularyItem.self, from: filename)
    }
}

