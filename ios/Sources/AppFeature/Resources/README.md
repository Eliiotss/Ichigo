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

## Reference sources (JLPT content)

The datasets aim to line up with the community-standard JLPT per-level lists. When
adding or verifying entries, cross-check against these sources:

| Source | Use | Link |
| --- | --- | --- |
| **Tanos.co.uk** — JLPT Vocabulary List | The community's most-referenced per-level vocabulary lists. | <https://www.tanos.co.uk/jlpt/> |
| **JLPTsensei.com** | Free per-level grammar, vocabulary and kanji lists. This project's grammar sets are levelled to its counts (N5 84 / N4 132 / N3 182). | <https://jlptsensei.com/> |
| **Jisho.org** | Verify each word's meaning, reading and JLPT level tag (N5–N1) per entry. | <https://jisho.org/> |
| **Official JLPT past papers (公式 JLPT 過去問)** | The most authoritative source, though not published as a per-level list. | <https://www.jlpt.jp/> |

Notes:

- The JLPT organisation has **not** published an official word/kanji list since
  2010, so per-level counts differ between sources — treat the numbers above as
  community references, not official figures.
- These lists are the authors' own compilations. Use them to source and verify
  **individual, factual** entries (readings, meanings, level tags), not to copy a
  whole list verbatim.
