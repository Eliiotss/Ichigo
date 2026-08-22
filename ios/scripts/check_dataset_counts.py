#!/usr/bin/env python3
"""Verify each level's advertised item count matches its bundled dataset.

Every level card shows a subtitle that opens with a count — "214 Essential
Kanji", "800 Kosakata Dasar", "84 Pola Tata Bahasa Dasar". Nothing ties that
number to the JSON file it describes, so editing a dataset without editing the
Swift silently leaves the app advertising a figure that is no longer true —
which is exactly how Kanji N3 came to claim 580 entries against a 214-entry
file.

This check re-reads both sides and fails when they disagree. Two rules:

* An **exact** figure ("214 Essential Kanji") must equal the dataset length.
* An **approximate** figure ("1.000+ Complex Kanji") is only allowed on a level
  whose dataset has not shipped — otherwise a real count is available and
  should be used.

A locked level may also carry no figure at all, which advertises nothing.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

LEVEL_SOURCES = (
    "Sources/AppFeature/KanjiModel.swift",
    "Sources/AppFeature/VocabModel.swift",
    "Sources/AppFeature/GrammarModel.swift",
)
RESOURCE_DIR = "Sources/AppFeature/Resources"

LEVEL_PATTERN = re.compile(
    r'id:\s*"(?P<id>[^"]+)".*?'
    r'description:\s*"(?P<description>[^"]*)".*?'
    r'isLocked:\s*(?P<locked>true|false).*?'
    r'jsonFile:\s*"(?P<json>[^"]+)"'
)

# A leading count, optionally with "." or "," thousands separators, optionally
# marked approximate with a trailing "+".
COUNT_PATTERN = re.compile(r"^(?P<digits>\d[\d.,]*)(?P<approx>\+)?\s")


def dataset_length(root: pathlib.Path, name: str) -> int | None:
    """Number of entries in a dataset, or None when the file has not shipped."""
    path = root / RESOURCE_DIR / f"{name}.json"
    if not path.exists():
        return None
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise ValueError(f"{name}.json is not a JSON array")
    return len(payload)


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    problems: list[str] = []
    checked = 0

    for swift_file in LEVEL_SOURCES:
        source = (root / swift_file).read_text(encoding="utf-8")
        for match in LEVEL_PATTERN.finditer(source):
            checked += 1
            level_id = match.group("id")
            description = match.group("description")
            json_name = match.group("json")
            actual = dataset_length(root, json_name)
            where = f"{swift_file}: {level_id}"

            count_match = COUNT_PATTERN.match(description)
            if count_match is None:
                # No figure advertised, so there is nothing that can go stale.
                continue

            declared = int(re.sub(r"[.,]", "", count_match.group("digits")))
            is_approximate = count_match.group("approx") is not None

            if actual is None:
                if not is_approximate:
                    problems.append(
                        f'{where} advertises an exact "{description}" but '
                        f"{json_name}.json has not shipped — use a \"{declared}+\" "
                        f"figure until it does"
                    )
                continue

            if is_approximate:
                problems.append(
                    f'{where} advertises an approximate "{description}" but '
                    f"{json_name}.json has shipped with {actual} entries — "
                    f"use the exact count"
                )
            elif declared != actual:
                problems.append(
                    f'{where} advertises "{description}" but {json_name}.json '
                    f"has {actual} entries"
                )

    if not checked:
        print("❌ Tidak ada level yang terbaca — pola parser mungkin sudah usang")
        return 1

    if problems:
        print("❌ Jumlah item level tidak cocok dengan datasetnya:")
        for problem in problems:
            print(f"   - {problem}")
        return 1

    print(f"✅ {checked} jumlah item level cocok dengan datasetnya")
    return 0


if __name__ == "__main__":
    sys.exit(main())
