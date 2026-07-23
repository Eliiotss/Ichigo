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
    let totalWords: Int
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let vocabularyLevels: [VocabularyLevel] = [
    VocabularyLevel(id: "N5", name: "Beginner", description: "~800 Kosakata Dasar", totalWords: 800, color: .green, bgColor: Color.green.opacity(0.15), isLocked: false, jsonFile: "VocabN5"),
    VocabularyLevel(id: "N4", name: "Elementary", description: "~1500 Kosakata", totalWords: 1500, color: .blue, bgColor: Color.blue.opacity(0.15), isLocked: false, jsonFile:"VocabN4"),
    VocabularyLevel(id: "N3", name: "Intermediate", description: "~3750 Kosakata", totalWords: 3750, color: .orange, bgColor: Color.orange.opacity(0.15), isLocked: false, jsonFile: "VocabN3"),
    VocabularyLevel(id: "N2", name: "Pre-Advanced ", description: "~6000 Kosakata", totalWords: 6000, color: .pink, bgColor: Color.pink.opacity(0.15), isLocked: true, jsonFile: "VocabN2"),
    VocabularyLevel(id: "N1", name: "Advanced ", description: "~10000 Kosakata", totalWords: 10000, color: .red, bgColor: Color.red.opacity(0.15), isLocked: true, jsonFile: "VocabN1")
]

// MARK: - Loader
enum VocabularyLoader {
    static func load(from filename: String) -> [VocabularyItem] {
        ResourceLoader.loadArray(VocabularyItem.self, from: filename)
    }
}

