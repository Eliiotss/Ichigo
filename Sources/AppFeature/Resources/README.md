# App datasets

Place the app's JSON datasets in this folder. They are bundled into the app via
`.process("Resources")` in `Package.swift` and loaded at runtime through
`JSONResourceCache`. The filename (without extension) must match the `jsonFile`
referenced by the matching level definition in the models.

Expected files and their schemas:

| File | Type (see) | Shape |
| --- | --- | --- |
| `Hiragana.json` | `KanaGroupJSON` (`HiraganaView.swift`) | `[ { title, subtitle, columns[], rows[][] } ]`, each cell `{ kana, romaji }` or `null`. Holds **both** hiragana and katakana groups; the view splits them by Unicode block into the two tabs. |
| `KanjiN5.json` … | `KanjiItem` (`KanjiModel.swift`) | `[ { id, kanji, onyomi, kunyomi, romaji, meaning, examples[] } ]` |
| `VocabN5.json` … | `VocabularyItem` (`VocabModel.swift`) | `[ { id, kanji, hiragana, arti, jenisKata } ]` |
| `GrammarN5.json` … | `GrammarItem` (`GrammarModel.swift`) | `[ { id, pattern, romaji, meaning, level, … } ]` |

When a dataset is missing the loaders return an empty array and the screen shows
a graceful empty state, so the app still builds and runs without data present.
