# Ichigo 🍓

Ichigo is a native **iOS app for learning Japanese** (JLPT), built with SwiftUI.
It bundles kana practice, kanji, vocabulary and grammar references, and a
flashcard trainer driven by the **FSRS-6** spaced-repetition algorithm. The
interface is in Bahasa Indonesia.

> The name *Ichigo* (いちご) means "strawberry" — and doubles as a play on
> *ichi-go* ("one word / one point") for language study.

---

## Features

| Module | What it does |
| --- | --- |
| **Huruf (Kana)** | Interactive Hiragana & Katakana tables (gojūon, dakuten/handakuten, yōon) with a multiple-choice flashcard drill and per-character mastery tracking. Yōon unlock after 50% of the base set is mastered. |
| **Kanji** | JLPT-levelled kanji browser with search across kanji, meaning, romaji, on'yomi, kun'yomi and example words; detail view with readings, examples and text-to-speech. |
| **Vocabulary** | Level-based vocabulary lists with search and part-of-speech filtering. |
| **Grammar** | Grammar pattern explorer with structure, usage notes, nuance, and example sentences. |
| **Flashcard** | A full FSRS-6 scheduler over the Vocabulary and Grammar decks — learning steps, due-card queues, daily new-card limits, streaks and analytics. |
| **Profile & Settings** | Daily target, streak, mastery and accuracy stats; configurable study reminder (local notification); progress reset. |

Additional platform features: light/dark mode, iPhone/iPad responsive layouts,
Japanese text-to-speech (`AVSpeechSynthesizer`), and offline-first data (all
content ships inside the app bundle as JSON).

---

## Architecture at a glance

Ichigo follows a layered, testable design. The spaced-repetition domain logic is
kept free of UI concerns so it can be unit-tested in isolation.

```
UI (SwiftUI Views)  ──►  ObservableObject stores  ──►  Domain logic  ──►  Persistence
   *View.swift             FlashcardStore /            FSRSMath,           UserDefaults
                           HiraganaStore               ReviewEngine,       stores +
                                                        QueueBuilder        JSON resources
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full breakdown, the folder
layout, and the data model.

---

## Requirements

- **Xcode 15+** (or Swift Playgrounds 4.4+ on iPadOS)
- **iOS 17.0+** deployment target
- No third-party dependencies — the project is 100% first-party Swift and the
  Apple SDKs.

---

## Getting started

```bash
git clone https://github.com/Eliiotss/Ichigo.git
cd Ichigo
open Package.swift        # opens the app package in Xcode
```

Then pick an iOS Simulator (or a device) and press **Run** (⌘R).

On iPad you can also open the folder directly in **Swift Playgrounds** and run it
there — the project is an app package (`Package.swift` with an `.iOSApplication`
product).

---

## Building & testing from the command line

Because the app depends on the iOS SDK, build it with `xcodebuild` against a
simulator destination (plain `swift build` targets macOS and cannot compile
UIKit):

```bash
# Build
xcodebuild build \
  -scheme Ichigo \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run the unit test suite
xcodebuild test \
  -scheme Ichigo \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

The unit tests (`Tests/AppModuleTests`) cover the FSRS math, the review-engine
state machine, the session queue builder, streak accounting and the data-model
helpers. CI runs the same commands on every push and pull request
(see [`.github/workflows/swift.yml`](.github/workflows/swift.yml)).

---

## Project layout

```
Ichigo/
├─ Package.swift                     # iOS app package manifest
├─ Sources/AppModule/
│  ├─ IchigoApp.swift                # @main entry + splash / preloading
│  ├─ *View.swift                    # SwiftUI screens
│  ├─ *Model.swift                   # data models + loaders
│  ├─ FlashcardModel.swift           # FSRS-6 engine, stores, analytics
│  ├─ JSONResourceCache.swift        # cached, thread-safe resource loading
│  ├─ ResourceLoader.swift, Logging.swift
│  └─ Resources/*.json               # kana, kanji, vocabulary, grammar datasets
└─ Tests/AppModuleTests/             # unit tests
```

A detailed description lives in [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Contributing

Contributions are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for
coding conventions, the commit style, and how to extend the datasets (e.g.
adding N4/N3 content). Notable changes are recorded in
[`CHANGELOG.md`](CHANGELOG.md).

---

## License

No license file is currently provided. Until one is added, all rights are
reserved by the repository owner.
