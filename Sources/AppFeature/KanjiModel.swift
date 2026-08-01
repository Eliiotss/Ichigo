import SwiftUI

// MARK: - Kanji Model
struct KanjiItem: Identifiable, Codable {
    let id: String
    let kanji: String
    let onyomi: String
    let kunyomi: String
    let romaji: String
    let meaning: String
    let examples: [KanjiExample]

    enum CodingKeys: String, CodingKey { case id, kanji, onyomi, kunyomi, romaji, meaning, examples }
}

struct KanjiExample: Codable {
    let word: String
    let reading: String
    let romaji: String
    let meaning: String
    let sentence: String?
    let sentenceFurigana: String?
    let sentenceMeaning: String?

    // Keys match the dataset (KanjiN5/N4/N3.json), which uses camelCase.
    enum CodingKeys: String, CodingKey {
        case word, reading, romaji, meaning
        case sentence, sentenceFurigana, sentenceMeaning
    }

    init(word: String, reading: String, romaji: String, meaning: String, sentence: String? = nil, sentenceFurigana: String? = nil, sentenceMeaning: String? = nil) {
        self.word = word
        self.reading = reading
        self.romaji = romaji
        self.meaning = meaning
        self.sentence = sentence
        self.sentenceFurigana = sentenceFurigana
        self.sentenceMeaning = sentenceMeaning
    }
}

// MARK: - JLPT Level Model
struct JLPTLevel: Identifiable {
    let id: String
    let name: String
    /// Subtitle shown under the level name. For an unlocked level it opens with
    /// the exact number of entries in `jsonFile`, which `scripts/check_dataset_counts.py`
    /// verifies; a locked level uses an approximate "1.000+" figure because its
    /// dataset has not shipped.
    let description: String
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let jlptLevels: [JLPTLevel] = [
    JLPTLevel(id: "N5", name: "Beginner", description: "120 Essential Kanji", color: AppTheme.levelColor("N5"), bgColor: AppTheme.levelBackground("N5"), isLocked: false, jsonFile: "KanjiN5"),
    JLPTLevel(id: "N4", name: "Elementary", description: "181 Essential Kanji", color: AppTheme.levelColor("N4"), bgColor: AppTheme.levelBackground("N4"), isLocked: false, jsonFile: "KanjiN4"),
    JLPTLevel(id: "N3", name: "Intermediate", description: "251 Essential Kanji", color: AppTheme.levelColor("N3"), bgColor: AppTheme.levelBackground("N3"), isLocked: false, jsonFile: "KanjiN3"),
    JLPTLevel(id: "N2", name: "Pre-Advanced", description: "1.000+ Complex Kanji", color: AppTheme.levelColor("N2"), bgColor: AppTheme.levelBackground("N2"), isLocked: true, jsonFile: "KanjiN2"),
    JLPTLevel(id: "N1", name: "Advanced", description: "2.000+ Master Kanji", color: AppTheme.levelColor("N1"), bgColor: AppTheme.levelBackground("N1"), isLocked: true, jsonFile: "KanjiN1")
]

// MARK: - JSON Loader
enum KanjiLoader {
    static func load(from filename: String) throws -> [KanjiItem] {
        try ResourceLoader.loadArray(KanjiItem.self, from: filename)
    }
}
