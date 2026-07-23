# Contributing to Ichigo

Thanks for your interest in improving Ichigo! This guide covers the workflow,
coding conventions, and how to extend the learning content.

## Prerequisites

- Xcode 15 or newer (iOS 17 SDK), or Swift Playgrounds 4.4+ on iPadOS.
- Optional: [SwiftLint](https://github.com/realm/SwiftLint) for local linting.

## Getting set up

```bash
git clone https://github.com/Eliiotss/Ichigo.git
cd Ichigo
open Package.swift
```

## Building and testing

Always run the test suite before opening a pull request:

```bash
xcodebuild test \
  -scheme Ichigo \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Adjust the simulator name to a device installed with your Xcode version
(`xcrun simctl list devices available`).

If you have SwiftLint installed, lint from the repository root:

```bash
swiftlint            # style + convention checks
swiftlint analyze    # requires a compilation log; catches unused code/imports
```

## Coding conventions

- **Language & style:** Swift, four-space indentation, follow the existing file
  organisation (`// MARK: -` sections). Prefer value types and immutability.
- **Naming:** descriptive, `camelCase` for members and `UpperCamelCase` for
  types. Match the surrounding code.
- **Views:** keep view bodies focused; extract subviews when a body grows large
  or is reused.
- **Domain logic:** keep scheduling/business logic free of SwiftUI so it stays
  unit-testable. New logic in `FlashcardModel.swift` (or a new domain file)
  should come with tests in `Tests/AppFeatureTests`.
- **Logging:** use the `Log` categories (`Log.resources`, `Log.flashcards`,
  `Log.notifications`) instead of `print`.
- **No secrets:** never commit credentials, tokens, API keys, or team
  identifiers.

## Commit messages

Use Conventional Commits so the history and changelog stay readable:

```
feat:     a new user-facing feature
fix:      a bug fix
refactor: code change that neither fixes a bug nor adds a feature
perf:     a performance improvement
test:     adding or fixing tests
docs:     documentation only
style:    formatting / whitespace
chore:    tooling, CI, dependencies
```

Example: `feat(kanji): add N4 kanji dataset`.

## Adding learning content

All content is JSON in `Sources/AppFeature/Resources/`. The filename must match
the `jsonFile` referenced by the level definition in the corresponding model.

- **Kanji** (`KanjiN4.json`, …) — array of `KanjiItem`
  (`id, kanji, onyomi, kunyomi, romaji, meaning, examples[]`). See
  `KanjiModel.swift`.
- **Vocabulary** (`VocabN4.json`, …) — array of `VocabularyItem`
  (`id, kanji, hiragana, arti, jenisKata`). See `VocabModel.swift`.
- **Grammar** (`GrammarN4.json`, …) — array of `GrammarItem` (see
  `GrammarModel.swift`; most fields have safe defaults so partial entries decode).
- **Kana** (`Hiragana.json`, `Katakana.json`) — array of `KanaGroupJSON`
  (`title, subtitle, columns, rows[][]`), where each cell is
  `{ "kana", "romaji" }` or `null`. Group titles containing "Yōon" / "Gabungan"
  are treated as the advanced set that unlocks after the base set is half
  mastered.

After adding a dataset, unlock its level by setting `isLocked: false` in the
matching `*Level` array. Validate the JSON before committing:

```bash
python3 -c "import json; json.load(open('Sources/AppFeature/Resources/KanjiN4.json'))"
```

Keep readings and meanings accurate — correctness matters more than volume for a
learning app.

## Pull requests

1. Branch from the default branch.
2. Keep changes focused; update tests and docs alongside code.
3. Ensure the build and tests pass.
4. Describe the change and its rationale in the PR body.
