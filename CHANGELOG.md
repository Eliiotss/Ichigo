# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Ichigo v2 visual design** across the app: a central `AppTheme` carrying the
  design's exact tokens (warm beige `#E7E0DC` page, white cards, plum `#2B2029`
  ink, muted `#B0A199`, blue `#2E7BFF` accent with its gradient pairs) and a
  rounded type ramp.
  - **Home**: "Okaeri 🍓" greeting, tappable gradient avatar, blue hero card
    (daily progress + Due / Streak / Mastered) and a tile grid with per-tile
    gradients.
  - **Profile**: rounded gradient header with ringed avatar and "JLPT Learner"
    badge, daily-target card, 2×2 stat grid and the answer-summary pills.
  - **Settings**: sectioned white cards with gradient icon chips and inset
    dividers; native controls retained.
  - **Browsing screens** (Vocabulary / Kanji / Grammar): pinned `ScreenHeader`,
    pill `SearchField` and `FilterChipRow` that stay fixed while content scrolls.
  - **App-wide type ramp**: every screen now draws its fonts from
    `AppTheme.rounded(...)` and its text colours, surfaces and shadows from the
    theme tokens, so the flashcard, kana, kanji, vocabulary and grammar screens
    match Home/Profile/Settings.
- **Google Drive backup & restore implementation** (`Sources/AppFeature/Backup/`):
  dependency-free OAuth 2.0 + PKCE via `ASWebAuthenticationSession`, tokens in the
  Keychain, and `URLSession` REST scoped to the Drive `appDataFolder`, plus the
  local progress snapshot (`BackupService`/`BackupPayload`). **Parked for a later
  release** — Settings advertises Akun, Cadangkan & Pulihkan and Sinkronisasi
  otomatis under "SEGERA HADIR" rather than exposing the controls. Setup notes for
  when it ships: `docs/GoogleDriveBackup.md`.

- **Swift package manifest** (`Package.swift`) defining the single-target iOS
  application — the project now has a canonical, buildable structure.
- **Unit test suite** (`Tests/AppFeatureTests`) covering the FSRS-6 math, the
  review-engine state machine, the session queue builder, day-boundary/streak
  accounting, the retention validator, analytics, deck-card mapping, the backup
  round-trip, PKCE and the account store.
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
  a single `Sources/AppFeature/` app target (all logic, UI, `@main` entry and the
  `Resources/` datasets). A single target is required by Swift Playgrounds, which
  cannot link `@main` when the app is split into a separate library and executable.
- **CI** now builds the app with `xcodebuild` against an iOS Simulator
  destination (`-sdk iphonesimulator`) instead of the previous `swift build`,
  which could not compile a UIKit/SwiftUI iOS app.
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
- Content covers JLPT **N5–N3** plus kana; N2/N1 datasets are the recommended
  next expansion (those levels stay gated until their data is added).
- Some deprecated SwiftUI APIs (`NavigationView`, `foregroundColor`,
  `accentColor`) are still in use; migrating to `NavigationStack` /
  `foregroundStyle` / `tint` is a recommended follow-up that needs on-device
  verification.
- User-facing strings are inline; extracting them into `Localizable.strings`
  would enable full localisation.
