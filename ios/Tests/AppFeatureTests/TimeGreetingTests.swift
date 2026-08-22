import XCTest
@testable import AppFeature

/// Unit tests untuk sapaan Beranda yang menyesuaikan jam. Fungsinya murni, jadi
/// setiap batas jam dapat diperiksa tanpa bergantung pada waktu perangkat.
final class TimeGreetingTests: XCTestCase {
    func testMorningBand() {
        XCTAssertEqual(TimeGreeting.text(hour: 5), "Selamat pagi")
        XCTAssertEqual(TimeGreeting.text(hour: 10), "Selamat pagi")
    }

    func testMiddayBand() {
        XCTAssertEqual(TimeGreeting.text(hour: 11), "Selamat siang")
        XCTAssertEqual(TimeGreeting.text(hour: 14), "Selamat siang")
    }

    func testAfternoonBand() {
        XCTAssertEqual(TimeGreeting.text(hour: 15), "Selamat sore")
        XCTAssertEqual(TimeGreeting.text(hour: 17), "Selamat sore")
    }

    func testNightBandWrapsAroundMidnight() {
        XCTAssertEqual(TimeGreeting.text(hour: 18), "Selamat malam")
        XCTAssertEqual(TimeGreeting.text(hour: 23), "Selamat malam")
        XCTAssertEqual(TimeGreeting.text(hour: 0), "Selamat malam")
        XCTAssertEqual(TimeGreeting.text(hour: 4), "Selamat malam")
    }
}
