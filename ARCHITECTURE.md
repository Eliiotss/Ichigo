# Architecture

Ichigo is a SwiftUI iOS application organised into clear layers so that the
spaced-repetition domain logic stays independent of the UI and can be unit
tested. This document describes the layers, the folder layout, the data model,
and the key subsystems.

## Layers

```
┌───────────────────────────────────────────────────────────────┐
│ Presentation  — SwiftUI views (*View.swift)                     │
│   ContentView, HomeView, KanjiView, VocabularyView, GrammarView │
│   HiraganaView, Flashcard*View, ProfileView, SettingsView       │
└───────────────┬───────────────────────────────────────────────┘
                │ observes
┌───────────────▼───────────────────────────────────────────────┐
│ State  — ObservableObject stores (@MainActor)                   │
│   FlashcardStore, HiraganaStore, NotificationManager,           │
│   AppLoadingState, FlashcardDeckSessionViewModel                │
└───────────────┬───────────────────────────────────────────────┘
                │ calls
┌───────────────▼───────────────────────────────────────────────┐
│ Domain  — pure, UI-free logic (unit tested)                     │
│   FSRSMath, FlashcardReviewEngine, FlashcardDeckQueueBuilder,   │
│   FlashcardDayBoundaryStore, FSRSRetentionValidator             │
└───────────────┬───────────────────────────────────────────────┘
                │ persists / reads
┌───────────────▼───────────────────────────────────────────────┐
│ Data  — persistence & content                                   │
│   *Store (UserDefaults), JSONResourceCache + ResourceLoader,    │
│   bundled JSON datasets (Resources/)                            │
└───────────────────────────────────────────────────────────────┘
```

Design principles applied: single responsibility per type, dependency injection
of the shared `FlashcardStore` from the app root, immutable value types for
models, and non-throwing loaders that degrade to a graceful empty state.

## Folder structure

```
Ichigo/
├─ Package.swift                 # iOSApplication product + AppModule + test target
├─ .swiftlint.yml                # local lint configuration
├─ .github/workflows/swift.yml   # CI: xcodebuild build + test on an iOS Simulator
├─ Sources/
│  └─ AppModule/
│     ├─ IchigoApp.swift         # @main App, splash screen, resource preloading
│     │
│     ├─ ContentView.swift       # TabView shell (Home / Profile / Settings)
│     ├─ HomeStatsCard.swift     # home dashboard widgets
│     │
│     ├─ KanjiView.swift         # kanji level list
│     ├─ KanjiListView.swift     # kanji grid + search
│     ├─ KanjiDetailView.swift   # kanji detail + TTS
│     ├─ KanjiModel.swift        # KanjiItem, JLPTLevel, loader
│     │
│     ├─ VocabView.swift         # vocabulary level list
│     ├─ VocabListView.swift     # vocabulary list + filter
│     ├─ VocabModel.swift        # VocabularyItem, level, loader
│     │
│     ├─ GrammarView.swift       # grammar level list
│     ├─ GrammarListView.swift   # grammar list + search
│     ├─ GrammarDetailView.swift # grammar detail
│     ├─ GrammarModel.swift      # GrammarItem, level, loader
│     │
│     ├─ HiraganaView.swift      # kana tables (hiragana/katakana)
│     ├─ HiraganaFlashcardView.swift  # kana multiple-choice drill + HiraganaStore
│     │
│     ├─ FlashcardModel.swift    # FSRS-6 engine, stores, analytics, streak
│     ├─ FlashcardLevelView.swift     # mode/level selection
│     ├─ FlashcardSessionView.swift   # review session + view model
│     │
│     ├─ ProfileView.swift       # stats dashboard
│     ├─ SettingsView.swift      # preferences, reminders, reset
│     │
│     ├─ NotificationManager.swift    # local daily reminder
│     ├─ AudioSpeechHelper.swift      # Japanese text-to-speech
│     ├─ UIStates.swift          # shared load-state + empty/error views
│     ├─ JSONResourceCache.swift # thread-safe cached JSON decoding
│     ├─ ResourceLoader.swift    # shared array-decode helper
│     ├─ Logging.swift           # os.Logger categories
│     └─ Resources/
│        ├─ Hiragana.json, Katakana.json
│        ├─ KanjiN5.json
│        ├─ VocabN5.json
│        └─ GrammarN5.json
└─ Tests/
   └─ AppModuleTests/            # FSRS, engine, queue, day-boundary, model tests
```

## Spaced repetition (FSRS-6)

The flashcard scheduler implements **FSRS-6** (Free Spaced Repetition Scheduler),
the algorithm used by modern Anki:

- **`FSRSMath`** — pure functions for retrievability, stability (on recall / on
  forget), difficulty updates and interval calculation. The decay/factor terms
  are derived from the personalised weight `w[20]`, per the official Open Spaced
  Repetition formulas.
- **`FlashcardReviewEngine`** — the state machine that combines FSRS with
  Anki-style learning steps. A card moves through `new → learning → review`, and
  `review → relearning` on a lapse. Grades are `Again / Hard / Good / Easy`.
- **`FlashcardDeckQueueBuilder`** — assembles a session: due cards first (sorted
  by how overdue they are, then by lapses), followed by new cards capped at the
  daily limit and reduced by cards already studied that day across sessions.
- **`FlashcardDayBoundaryStore`** — timezone-aware day keys drive streak counting
  and once-per-day resets.
- **`FSRSRetentionValidator`** — a safety net that flags impossible progress
  values (negative counters, out-of-range difficulty, etc.).

Settings (`FlashcardSettings`) expose the tunable parameters — new cards/day,
learning steps, desired retention, maximum interval, leech threshold and the 21
FSRS weights — and are persisted as JSON.

## Persistence

- **User progress** (SRS state, review logs, analytics, streaks, kana mastery,
  settings) is stored in `UserDefaults` via small, single-purpose store types.
  Corrupt payloads are backed up under a `*_corrupt_backup_*` key and reset
  rather than crashing.
- **Content** (kana/kanji/vocabulary/grammar) ships as JSON in the app bundle and
  is read through `JSONResourceCache`, an `NSLock`-guarded cache that keeps both
  raw `Data` and decoded values, with size-bounded eviction. `ResourceLoader`
  wraps it with a consistent non-throwing, logged contract.

## Concurrency

- UI-facing stores and view models are annotated `@MainActor`.
- Content decoding runs on `Task.detached(priority: .userInitiated)` and results
  are hopped back to the main actor before mutating `@Published` state.
- `JSONResourceCache` is internally synchronised with `NSLock`, making it safe to
  call from detached tasks (e.g. the startup preloader).

## Localisation

The UI copy is Bahasa Indonesia. User-facing strings currently live inline; a
future step is to extract them into a `Localizable.strings` catalogue (see
CONTRIBUTING and the changelog's "next steps").
