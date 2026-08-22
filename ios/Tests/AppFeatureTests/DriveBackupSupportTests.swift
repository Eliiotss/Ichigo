import XCTest
@testable import AppFeature

/// Tests for the small, pure pieces of the Drive backup feature: PKCE and the
/// OAuth config derivation. The network and Keychain paths are integration
/// concerns exercised on-device.
final class DriveBackupSupportTests: XCTestCase {

    // MARK: - PKCE

    func testChallengeIsDeterministicAndURLSafe() {
        let verifier = "a-sample-code-verifier-1234567890"
        let first = PKCE.challenge(for: verifier)
        let second = PKCE.challenge(for: verifier)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
        XCTAssertFalse(first.contains("+"))
        XCTAssertFalse(first.contains("/"))
        XCTAssertFalse(first.contains("="))
    }

    func testDifferentVerifiersProduceDifferentChallenges() {
        XCTAssertNotEqual(PKCE.challenge(for: "verifier-one"), PKCE.challenge(for: "verifier-two"))
    }

    func testRandomStringIsUniqueAndURLSafe() {
        let a = PKCE.randomString()
        let b = PKCE.randomString()
        XCTAssertNotEqual(a, b)
        for value in [a, b] {
            XCTAssertFalse(value.contains("+"))
            XCTAssertFalse(value.contains("/"))
            XCTAssertFalse(value.contains("="))
        }
    }

    // MARK: - Config

    func testRedirectSchemeDerivedFromClientID() {
        let config = GoogleDriveConfig(clientID: "123456-abcdef.apps.googleusercontent.com")
        XCTAssertEqual(config.redirectScheme, "com.googleusercontent.apps.123456-abcdef")
        XCTAssertEqual(config.redirectURI, "com.googleusercontent.apps.123456-abcdef:/oauth2redirect")
    }

    func testConfigLoadReturnsNilWithoutPlist() {
        // The test bundle does not contain a GoogleOAuth.plist.
        XCTAssertNil(GoogleDriveConfig.load(bundle: Bundle(for: Self.self)))
    }
}
