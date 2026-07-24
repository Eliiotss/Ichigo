import XCTest
@testable import AppFeature

/// Round-trip tests for the backup snapshot: gather from one `UserDefaults`,
/// serialise, deserialise, and restore into another, asserting equality.
final class BackupServiceTests: XCTestCase {
    private var sourceName = ""
    private var targetName = ""
    private var source: UserDefaults!
    private var target: UserDefaults!

    override func setUp() {
        super.setUp()
        sourceName = "ichigo.test.source.\(UUID().uuidString)"
        targetName = "ichigo.test.target.\(UUID().uuidString)"
        source = UserDefaults(suiteName: sourceName)
        target = UserDefaults(suiteName: targetName)
    }

    override func tearDown() {
        source.removePersistentDomain(forName: sourceName)
        target.removePersistentDomain(forName: targetName)
        source = nil
        target = nil
        super.tearDown()
    }

    func testRoundTripPreservesAllValues() throws {
        source.set(Data("progress".utf8), forKey: BackupKeys.flashcardProgress)
        source.set(Data("settings".utf8), forKey: BackupKeys.flashcardSettings)
        source.set(Data("reviews".utf8), forKey: BackupKeys.flashcardReviews)
        source.set(Data("hira".utf8), forKey: BackupKeys.hiraganaCount)
        source.set(7, forKey: BackupKeys.streak)
        source.set("2026-03-10-Asia/Jakarta", forKey: BackupKeys.lastStudyDayKey)
        source.set(["a", "b"], forKey: BackupKeys.newTodayPrefix + "vocabulary_N5_2026-03-10")
        source.set(Data("daily".utf8), forKey: BackupKeys.dailyAnalyticsPrefix + "2026-03-10")
        source.set("Budi", forKey: BackupKeys.userName)
        source.set(30, forKey: BackupKeys.dailyTarget)
        source.set(true, forKey: BackupKeys.notifEnabled)
        source.set(21, forKey: BackupKeys.notifHour)

        let payload = BackupService.makePayload(from: source)
        let encoded = try BackupService.encode(payload)
        let decoded = try BackupService.decode(encoded)
        BackupService.restore(decoded, into: target)

        XCTAssertEqual(target.data(forKey: BackupKeys.flashcardProgress), Data("progress".utf8))
        XCTAssertEqual(target.data(forKey: BackupKeys.flashcardSettings), Data("settings".utf8))
        XCTAssertEqual(target.data(forKey: BackupKeys.flashcardReviews), Data("reviews".utf8))
        XCTAssertEqual(target.data(forKey: BackupKeys.hiraganaCount), Data("hira".utf8))
        XCTAssertEqual(target.integer(forKey: BackupKeys.streak), 7)
        XCTAssertEqual(target.string(forKey: BackupKeys.lastStudyDayKey), "2026-03-10-Asia/Jakarta")
        XCTAssertEqual(target.stringArray(forKey: BackupKeys.newTodayPrefix + "vocabulary_N5_2026-03-10"), ["a", "b"])
        XCTAssertEqual(target.data(forKey: BackupKeys.dailyAnalyticsPrefix + "2026-03-10"), Data("daily".utf8))
        XCTAssertEqual(target.string(forKey: BackupKeys.userName), "Budi")
        XCTAssertEqual(target.integer(forKey: BackupKeys.dailyTarget), 30)
        XCTAssertTrue(target.bool(forKey: BackupKeys.notifEnabled))
        XCTAssertEqual(target.integer(forKey: BackupKeys.notifHour), 21)
    }

    func testEncodedPayloadDecodesToEqualValue() throws {
        source.set(5, forKey: BackupKeys.streak)
        source.set(Data("x".utf8), forKey: BackupKeys.flashcardProgress)
        let payload = BackupService.makePayload(from: source, date: Date(timeIntervalSince1970: 1_700_000_000))
        let decoded = try BackupService.decode(BackupService.encode(payload))
        XCTAssertEqual(decoded, payload)
        XCTAssertEqual(decoded.schemaVersion, BackupService.schemaVersion)
    }

    func testMissingKeysAreOmitted() {
        let payload = BackupService.makePayload(from: source)
        XCTAssertNil(payload.flashcardProgress)
        XCTAssertNil(payload.streak)
        XCTAssertTrue(payload.newTodayLists.isEmpty)
    }
}
