import XCTest
@testable import AppFeature

/// Memastikan pilihan mode tampilan bertahan dan tahan terhadap nilai tak dikenal.
final class AppAppearanceTests: XCTestCase {
    func testStoredValueRoundTrips() {
        for option in AppAppearance.allCases {
            XCTAssertEqual(AppAppearance.from(storedValue: option.rawValue), option)
        }
    }

    func testUnknownOrEmptyValueFallsBackToSystem() {
        XCTAssertEqual(AppAppearance.from(storedValue: ""), .system)
        XCTAssertEqual(AppAppearance.from(storedValue: "sepia"), .system)
    }

    func testOnlySystemDefersToTheDevice() {
        XCTAssertNil(AppAppearance.system.preferredColorScheme)
        XCTAssertEqual(AppAppearance.light.preferredColorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.preferredColorScheme, .dark)
    }
}
