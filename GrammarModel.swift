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
    let description: String
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

let grammarLevels: [GrammarLevel] = [
    GrammarLevel(id: "N5", name: "Beginner", description: "Tata Bahasa Dasar", color: .green, bgColor: Color.green.opacity(0.15), isLocked: false, jsonFile: "GrammarN5"),
    GrammarLevel(id: "N4", name: "Elementary", description: "Tata Bahasa Dasar+", color: .blue, bgColor: Color.blue.opacity(0.15), isLocked: false, jsonFile: "GrammarN4"),
    GrammarLevel(id: "N3", name: "Intermediate", description: "Tata Bahasa Menengah", color: .orange, bgColor: Color.orange.opacity(0.15), isLocked: false, jsonFile: "GrammarN3"),
    GrammarLevel(id: "N2", name: "Pre-Advanced", description: "Tata Bahasa Lanjutan", color: .pink, bgColor: Color.pink.opacity(0.15), isLocked: true, jsonFile: "GrammarN2"),
    GrammarLevel(id: "N1", name: "Advanced", description: "Tata Bahasa Master", color: .red, bgColor: Color.red.opacity(0.15), isLocked: true, jsonFile: "GrammarN1")
]

// MARK: - Grammar JSON Loader
final class GrammarLoader {
    static func load(from filename: String) -> [GrammarItem] {
        if let items = loadUsingResourceCache(filename: filename) {
            return items
        }
        
        if let items = loadDirectlyFromBundle(filename: filename) {
            return items
        }
        
        print("❌ Grammar file benar-benar tidak bisa dibaca: \(filename).json")
        return []
    }
    
    private static func loadUsingResourceCache(filename: String) -> [GrammarItem]? {
        do {
            let items = try JSONResourceCache.shared.decode([GrammarItem].self, filename: filename)
            print("✅ Loaded \(items.count) grammar items from cache: \(filename).json")
            return items
        } catch {
            print("⚠️ Cache gagal load \(filename).json")
            print("📌 Cache error: \(error)")
            return nil
        }
    }
    
    private static func loadDirectlyFromBundle(filename: String) -> [GrammarItem]? {
        let urls: [URL?] = [
            Bundle.main.url(forResource: filename, withExtension: "json"),
            Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Resources"),
            Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Sources/AppModule/Resources")
        ]
        
        guard let url = urls.compactMap({ $0 }).first else {
            print("❌ File tidak ditemukan di Bundle.main: \(filename).json")
            print("📌 Pastikan nama file persis: \(filename).json")
            print("📌 Pastikan file masuk target/resource Swift Playgrounds")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([GrammarItem].self, from: data)
            print("✅ Loaded \(items.count) grammar items directly from bundle: \(url.lastPathComponent)")
            return items
        } catch {
            print("❌ Gagal decode langsung: \(filename).json")
            print("📌 URL: \(url)")
            print("📌 Decode error: \(error)")
            return nil
        }
    }
}
