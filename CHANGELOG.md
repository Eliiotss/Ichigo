# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Manual Google Drive backup & restore** (Settings → *Cadangan*). Dependency-free
  OAuth 2.0 + PKCE via `ASWebAuthenticationSession`, tokens in the Keychain, and
  `URLSession` REST scoped to the Drive `appDataFolder`. Backs up the local
  progress snapshot (`BackupService`/`BackupPayload`) to a single
  `ichigo-backup.json`. The feature stays off until an OAuth client ID is supplied
  via a git-ignored `GoogleOAuth.plist`; see `docs/GoogleDriveBackup.md`. Replaces
  the previous "Backup/restore (coming soon)" placeholder.

- **Swift package manifest** (`Package.swift`) defining the iOS application
  product, the `AppModule` target and an `AppModuleTests` test target — the
  project now has a canonical, buildable structure.
- **Unit test suite** (`Tests/AppModuleTests`) covering the FSRS-6 math, the
  review-engine state machine, the session queue builder, day-boundary/streak
  accounting, the retention validator, analytics and deck-card mapping.
- **Datasets folder** (`Sources/AppFeature/Resources/`) documented as the drop-in
  location for the maintainer's JSON datasets (kana, kanji, vocabulary, grammar),
  with the expected schemas in its `README.md`. The datasets themselves are
  supplied separately by the maintainer.
- **Unified logging** via `os.Logger` (`Log` with `resources`, `flashcards` and
  `notifications` categories).
- **Shared `ResourceLoader`** that centralises JSON array decoding and error
  handling for all loaders.
- **Documentation:** `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, this
  changelog, and a `.swiftlint.yml` configuration.

### Changed
- **Project restructured** from a flat pile of files at the repository root into
  a library (`Sources/AppFeature/`, all logic + UI + `Resources/`) plus a thin
  `@main` executable (`Sources/AppModule/`). The library split lets the XCTest
  target import the code, which an executable target carrying `@main` cannot
  provide under `xcodebuild`.
- **CI** now builds and tests the app with `xcodebuild` against an iOS Simulator
  destination instead of the previous `swift build`/`swift test`, which could not
  compile a UIKit/SwiftUI iOS app.
- **Consistent branding:** the app entry point was renamed `MyApp` → `IchigoApp`
  and stray "NihongoMaster" / "Nihongo Master" strings are now "Ichigo".
- **Consistent filenames:** `ProfilView.swift` → `ProfileView.swift`,
  `SetingsView.swift` → `SettingsView.swift`.
- **Single source of truth for flashcards:** the flashcard flow now receives the
  shared `FlashcardStore` from the app root via dependency injection instead of
  creating a second, divergent store instance.
- **`GrammarListView`** loads its data with structured concurrency
  (`Task.detached`) to match the other list screens, replacing nested
  `DispatchQueue` calls.
- **Kana quiz** now builds answer choices from distinct distractors only.
- Loaders (`KanjiLoader`, `VocabularyLoader`, `GrammarLoader`, `KanaLoader`) are
  now stateless enums routed through `ResourceLoader`.

### Fixed
- **Level cards** for Kanji, Vocabulary and Grammar had duplicated SwiftUI
  modifiers that silently overrode the description styling and hid the item
  count; the intended two-line layout (description + count) is restored, and the
  previously unused `totalKanji` / `totalWords` fields are now shown.
- **Kana flashcard** could render multiple "correct" answer buttons and emit
  duplicate `ForEach` identifiers when the distractor pool was small; choices are
  now guaranteed distinct.
- **Notification scheduling** now logs failures from `UNUserNotificationCenter`.

### Removed
- Dead code: the unused `AppState` observable object, the legacy `FlashcardItem`
  type and its initializer, the unused `itemsPerLevel` storage, and the no-op
  `NotificationManager.skipTodayIfTargetMet` method.
- Debug `print` statements across the loaders (replaced by unified logging).
- Artificial fixed-delay spinners on the static Kanji/Grammar/Vocabulary level
  lists, improving perceived navigation speed.
- Leftover review-note comments in the source.

### Known limitations / next steps
- Content currently covers JLPT **N5** plus full kana; N4–N1 datasets are the
  recommended next expansion (levels remain gated until their data is added).
- Some deprecated SwiftUI APIs (`NavigationView`, `foregroundColor`,
  `accentColor`) are still in use; migrating to `NavigationStack` /
  `foregroundStyle` / `tint` is a recommended follow-up that needs on-device
  verification.
- User-facing strings are inline; extracting them into `Localizable.strings`
  would enable full localisation.
