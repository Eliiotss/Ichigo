import SwiftUI
import Foundation

// MARK: - Grammar Data Model
struct GrammarItem: Identifiable, Codable {
    let id: String
    let pattern: String
    let romaji: String
    let meaning: String
    let level: String
    let difficulty: Int
    let structure: String
    let tags: [String]
    let treeCategory: String
    let relatedGrammarIds: [String]
    let nuance: String
    let frequency: String
    let commonMistakes: [String]
    let explanation: String
    let usage: [String]
    let examples: [GrammarExample]
    let bunpouPersamaan: [String]

    enum CodingKeys: String, CodingKey {
        case id, pattern, romaji, meaning, level, difficulty, structure, tags
        case treeCategory, relatedGrammarIds, nuance, frequency, commonMistakes
        case explanation, usage, examples, bunpouPersamaan
    }

    init(
        id: String,pattern: String,romaji: String,meaning: String,level: String,difficulty: Int,
        structure: String,tags: [String],treeCategory: String,relatedGrammarIds: [String],
        nuance: String,frequency: String,commonMistakes: [String],explanation: String,
        usage: [String],examples: [GrammarExample],bunpouPersamaan: [String] = []
    ) {
        self.id = id
        self.pattern = pattern
        self.romaji = romaji
        self.meaning = meaning
        self.level = level
        self.difficulty = difficulty
        self.structure = structure
        self.tags = tags
        self.treeCategory = treeCategory
        self.relatedGrammarIds = relatedGrammarIds
        self.nuance = nuance
        self.frequency = frequency
        self.commonMistakes = commonMistakes
        self.explanation = explanation
        self.usage = usage
        self.examples = examples
        self.bunpouPersamaan = bunpouPersamaan
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        pattern = try c.decodeIfPresent(String.self, forKey: .pattern) ?? ""
        romaji = try c.decodeIfPresent(String.self, forKey: .romaji) ?? ""
        meaning = try c.decodeIfPresent(String.self, forKey: .meaning) ?? ""
        level = try c.decodeIfPresent(String.self, forKey: .level) ?? "N4"
        difficulty = try c.decodeIfPresent(Int.self, forKey: .difficulty) ?? 3
        structure = try c.decodeIfPresent(String.self, forKey: .structure) ?? ""
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        treeCategory = try c.decodeIfPresent(String.self, forKey: .treeCategory) ?? "Grammar"
        relatedGrammarIds = try c.decodeIfPresent([String].self, forKey: .relatedGrammarIds) ?? []
        nuance = try c.decodeIfPresent(String.self, forKey: .nuance) ?? "Common"
        frequency = try c.decodeIfPresent(String.self, forKey: .frequency) ?? "Common"
        commonMistakes = try c.decodeIfPresent([String].self, forKey: .commonMistakes) ?? []
        explanation = try c.decodeIfPresent(String.self, forKey: .explanation) ?? ""
        usage = try c.decodeIfPresent([String].self, forKey: .usage) ?? []
        examples = try c.decodeIfPresent([GrammarExample].self, forKey: .examples) ?? []
        bunpouPersamaan = try c.decodeIfPresent([String].self, forKey: .bunpouPersamaan) ?? []
    }
}

struct GrammarExample: Codable {
    let japanese: String
    let romaji: String
    let translation: String

    enum CodingKeys: String, CodingKey {
        case japanese, romaji, translation
    }

    init(japanese: String, romaji: String, translation: String) {
        self.japanese = japanese
        self.romaji = romaji
        self.translation = translation
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        japanese = try c.decodeIfPresent(String.self, forKey: .japanese) ?? ""
        romaji = try c.decodeIfPresent(String.self, forKey: .romaji) ?? ""
        translation = try c.decodeIfPresent(String.self, forKey: .translation) ?? ""
    }
}

extension GrammarItem {
    static let sample = GrammarItem(
        id: "N5_G001",
        pattern: "〜てください",
        romaji: "te kudasai",
        meaning: "Tolong lakukan...",
        level: "N5",
        difficulty: 1,
        structure: "Verb-te + ください",
        tags: ["KK Bentuk -Te", "ください"],
        treeCategory: "Permintaan",
        relatedGrammarIds: [],
        nuance: "Common",
        frequency: "Very Common",
        commonMistakes: [],
        explanation: "Digunakan untuk meminta seseorang melakukan sesuatu dengan sopan.",
        usage: [
            "Dipakai untuk meminta orang lain melakukan sesuatu dengan sopan.",
            "Cocok untuk percakapan sehari-hari dan situasi formal ringan."
        ],
        examples: [
            GrammarExample(japanese: "ここに名前を書いてください。", romaji: "Koko ni namae o kaite kudasai.", translation: "Tolong tulis nama di sini."),
            GrammarExample(japanese: "ちょっと待ってください。", romaji: "Chotto matte kudasai.", translation: "Tolong tunggu sebentar.")
        ],
        bunpouPersamaan: []
    )
}

// MARK: - Grammar Level Config
struct GrammarLevel: Identifiable {
    let id: String
    let name: String
    /// Subtitle shown under the level name, in the same shape as the kanji and
    /// vocabulary levels: an unlocked level opens with the exact number of
    /// patterns in `jsonFile`. The locked levels carry no figure because no
    /// pattern count for them has been settled on yet.
    let description: String
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let grammarLevels: [GrammarLevel] = [
    GrammarLevel(id: "N5", name: "Beginner", description: "84 Pola Tata Bahasa Dasar", color: AppTheme.levelColor("N5"), bgColor: AppTheme.levelBackground("N5"), isLocked: false, jsonFile: "GrammarN5"),
    GrammarLevel(id: "N4", name: "Elementary", description: "131 Pola Tata Bahasa Dasar+", color: AppTheme.levelColor("N4"), bgColor: AppTheme.levelBackground("N4"), isLocked: false, jsonFile: "GrammarN4"),
    GrammarLevel(id: "N3", name: "Intermediate", description: "170 Pola Tata Bahasa Menengah", color: AppTheme.levelColor("N3"), bgColor: AppTheme.levelBackground("N3"), isLocked: false, jsonFile: "GrammarN3"),
    GrammarLevel(id: "N2", name: "Pre-Advanced", description: "Pola Tata Bahasa Lanjutan", color: AppTheme.levelColor("N2"), bgColor: AppTheme.levelBackground("N2"), isLocked: true, jsonFile: "GrammarN2"),
    GrammarLevel(id: "N1", name: "Advanced", description: "Pola Tata Bahasa Master", color: AppTheme.levelColor("N1"), bgColor: AppTheme.levelBackground("N1"), isLocked: true, jsonFile: "GrammarN1")
]

// MARK: - Grammar JSON Loader
enum GrammarLoader {
    static func load(from filename: String) throws -> [GrammarItem] {
        try ResourceLoader.loadArray(GrammarItem.self, from: filename)
    }
}
