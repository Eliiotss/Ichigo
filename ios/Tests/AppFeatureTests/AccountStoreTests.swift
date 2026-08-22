import XCTest
@testable import AppFeature

/// Tests for ``AccountStore``, the single source of truth for account details
/// shared by Home, Profile, Settings and the Drive backup flow.
@MainActor
final class AccountStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ichigo.account.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDefaultsWhenNothingStored() {
        let store = AccountStore(defaults: defaults)
        XCTAssertEqual(store.displayName, "User123")
        XCTAssertEqual(store.email, "")
        XCTAssertFalse(store.isLinkedToGoogle)
    }

    func testChangesPersistToBackupKeys() {
        let store = AccountStore(defaults: defaults)
        store.displayName = "Budi Santoso"
        store.email = "budi@contoh.com"
        XCTAssertEqual(defaults.string(forKey: BackupKeys.userName), "Budi Santoso")
        XCTAssertEqual(defaults.string(forKey: BackupKeys.userEmail), "budi@contoh.com")
    }

    func testInitials() {
        let store = AccountStore(defaults: defaults)
        store.displayName = "Budi Santoso"
        XCTAssertEqual(store.initials, "BS")
        store.displayName = "Budi"
        XCTAssertEqual(store.initials, "BU")
        store.displayName = "   "
        XCTAssertEqual(store.initials, "U")
    }

    func testLinkingGoogleAdoptsEmailWhenEmpty() {
        let store = AccountStore(defaults: defaults)
        store.linkGoogleAccount(email: "user@gmail.com")
        XCTAssertTrue(store.isLinkedToGoogle)
        XCTAssertEqual(store.linkedGoogleEmail, "user@gmail.com")
        XCTAssertEqual(store.email, "user@gmail.com")
    }

    func testLinkingGoogleKeepsUserProvidedEmail() {
        let store = AccountStore(defaults: defaults)
        store.email = "pribadi@contoh.com"
        store.linkGoogleAccount(email: "user@gmail.com")
        XCTAssertEqual(store.email, "pribadi@contoh.com")
        XCTAssertEqual(store.linkedGoogleEmail, "user@gmail.com")
    }

    func testUnlinkClearsOnlyTheGoogleAccount() {
        let store = AccountStore(defaults: defaults)
        store.linkGoogleAccount(email: "user@gmail.com")
        store.unlinkGoogleAccount()
        XCTAssertFalse(store.isLinkedToGoogle)
        XCTAssertEqual(store.email, "user@gmail.com", "profile email survives sign-out")
    }

    func testReloadPicksUpRestoredValues() {
        let store = AccountStore(defaults: defaults)
        defaults.set("Dipulihkan", forKey: BackupKeys.userName)
        defaults.set("restore@contoh.com", forKey: BackupKeys.userEmail)
        store.reload()
        XCTAssertEqual(store.displayName, "Dipulihkan")
        XCTAssertEqual(store.email, "restore@contoh.com")
    }
}
