import XCTest
@testable import AppFeature

/// Tests for classifying a `KanaGroup` by script. The kana dataset ships
/// hiragana and katakana in a single file, and `HiraganaView` relies on this to
/// route each group to the correct tab.
final class KanaGroupScriptTests: XCTestCase {
    private func group(_ kana: String) -> KanaGroup {
        KanaGroup(title: "t", subtitle: "", items: [[KanaItem(kana: kana, romaji: "x")]], columns: ["A"])
    }

    func testHiraganaIsNotKatakana() {
        XCTAssertFalse(group("あ").isKatakanaScript)
        XCTAssertFalse(group("きゃ").isKatakanaScript) // yōon
        XCTAssertFalse(group("が").isKatakanaScript)   // dakuten
    }

    func testKatakanaIsDetected() {
        XCTAssertTrue(group("ア").isKatakanaScript)
        XCTAssertTrue(group("キャ").isKatakanaScript)  // yōon
        XCTAssertTrue(group("ガ").isKatakanaScript)    // dakuten
    }

    func testEmptyCellsDefaultToHiragana() {
        let empty = KanaGroup(title: "t", subtitle: "", items: [[nil]], columns: ["A"])
        XCTAssertFalse(empty.isKatakanaScript)
    }

    func testCombinedGroupsSplitEvenly() {
        let groups = [group("あ"), group("ア"), group("か"), group("カ")]
        XCTAssertEqual(groups.filter { !$0.isKatakanaScript }.count, 2)
        XCTAssertEqual(groups.filter { $0.isKatakanaScript }.count, 2)
    }
}
