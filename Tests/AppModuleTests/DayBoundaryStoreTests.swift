import XCTest
@testable import AppModule

/// Tests for ``FlashcardDayBoundaryStore`` streak accounting. The store persists
/// to `UserDefaults.standard`, so each test clears the relevant keys first to stay
/// isolated and deterministic.
final class DayBoundaryStoreTests: XCTestCase {
    private let keys = [
        "flashcard_last_study_day_key_v1",
        "flashcard_last_reset_day_key_v1",
        "flashcard_streak_v1",
        "flashcard_last_study_date"
    ]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    override func setUp() {
        super.setUp()
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testFirstStudyStartsStreakAtOne() {
        let store = FlashcardDayBoundaryStore()
        store.registerStudy(date: date(2026, 3, 10), calendar: calendar)
        XCTAssertEqual(store.currentStreak, 1)
    }

    func testConsecutiveDaysIncrementStreak() {
        let store = FlashcardDayBoundaryStore()
        store.registerStudy(date: date(2026, 3, 10), calendar: calendar)
        store.registerStudy(date: date(2026, 3, 11), calendar: calendar)
        store.registerStudy(date: date(2026, 3, 12), calendar: calendar)
        XCTAssertEqual(store.currentStreak, 3)
    }

    func testSameDayDoesNotDoubleCount() {
        let store = FlashcardDayBoundaryStore()
        store.registerStudy(date: date(2026, 3, 10, hour: 9), calendar: calendar)
        store.registerStudy(date: date(2026, 3, 10, hour: 21), calendar: calendar)
        XCTAssertEqual(store.currentStreak, 1)
    }

    func testGapResetsStreak() {
        let store = FlashcardDayBoundaryStore()
        store.registerStudy(date: date(2026, 3, 10), calendar: calendar)
        store.registerStudy(date: date(2026, 3, 13), calendar: calendar) // two-day gap
        XCTAssertEqual(store.currentStreak, 1)
    }

    func testDailyResetFiresOncePerDay() {
        let store = FlashcardDayBoundaryStore()
        XCTAssertTrue(store.markDailyResetIfNeeded(date: date(2026, 3, 10), calendar: calendar))
        XCTAssertFalse(store.markDailyResetIfNeeded(date: date(2026, 3, 10, hour: 23), calendar: calendar))
        XCTAssertTrue(store.markDailyResetIfNeeded(date: date(2026, 3, 11), calendar: calendar))
    }
}
