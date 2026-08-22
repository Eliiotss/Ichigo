import XCTest
@testable import AppFeature

/// Ensures `KanjiExample` decodes the dataset's camelCase example-sentence keys
/// (`sentence`, `sentenceFurigana`, `sentenceMeaning`) so they can be shown in the
/// Kanji detail view.
final class KanjiModelTests: XCTestCase {
    func testDecodesCamelCaseSentenceFields() throws {
        let json = Data("""
        {
            "word": "日本",
            "reading": "にほん",
            "romaji": "nihon",
            "meaning": "Jepang",
            "sentence": "私は日本を勉強します。",
            "sentenceFurigana": "私は日本(にほん)をべんきょうします。",
            "sentenceMeaning": "Saya mempelajari Jepang."
        }
        """.utf8)

        let example = try JSONDecoder().decode(KanjiExample.self, from: json)
        XCTAssertEqual(example.word, "日本")
        XCTAssertEqual(example.reading, "にほん")
        XCTAssertEqual(example.sentence, "私は日本を勉強します。")
        XCTAssertEqual(example.sentenceFurigana, "私は日本(にほん)をべんきょうします。")
        XCTAssertEqual(example.sentenceMeaning, "Saya mempelajari Jepang.")
    }

    func testDecodesWithoutOptionalSentenceFields() throws {
        let json = Data("""
        { "word": "学", "reading": "がく", "romaji": "gaku", "meaning": "belajar" }
        """.utf8)
        let example = try JSONDecoder().decode(KanjiExample.self, from: json)
        XCTAssertNil(example.sentence)
        XCTAssertNil(example.sentenceFurigana)
        XCTAssertNil(example.sentenceMeaning)
    }
}
