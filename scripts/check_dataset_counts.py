#!/usr/bin/env python3
"""Verify each level's advertised item count matches its bundled dataset.

The level lists carry a hand-written count (``totalKanji``, ``totalWords``,
``totalPatterns``) that the cards show to the user. Nothing ties that number to
the JSON file it describes, so editing a dataset without editing the Swift
silently leaves the app advertising a figure that is no longer true — which is
exactly how Kanji N3 came to claim 580 entries against a 214-entry file.

This check re-reads both sides and fails when they disagree. A level whose
dataset has not shipped must declare ``0``: it renders no count at all, so any
other value would be advertising data that does not exist.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

# (Swift file, count field, path is relative to Sources/AppFeature/Resources)
LEVEL_SOURCES = (
    ("Sources/AppFeature/KanjiModel.swift", "totalKanji"),
    ("Sources/AppFeature/VocabModel.swift", "totalWords"),
    ("Sources/AppFeature/GrammarModel.swift", "totalPatterns"),
)
RESOURCE_DIR = "Sources/AppFeature/Resources"

LEVEL_PATTERN = re.compile(
    r'id:\s*"(?P<id>[^"]+)".*?'
    r'(?P<field>total\w+):\s*(?P<count>\d+).*?'
    r'isLocked:\s*(?P<locked>true|false).*?'
    r'jsonFile:\s*"(?P<json>[^"]+)"'
)


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

    for swift_file, field in LEVEL_SOURCES:
        source = (root / swift_file).read_text(encoding="utf-8")
        for match in LEVEL_PATTERN.finditer(source):
            if match.group("field") != field:
                continue
            checked += 1
            level_id = match.group("id")
            declared = int(match.group("count"))
            json_name = match.group("json")
            actual = dataset_length(root, json_name)
            where = f"{swift_file}: {level_id} ({field})"

            if actual is None:
                if declared != 0:
                    problems.append(
                        f"{where} declares {declared} but {json_name}.json has "
                        f"not shipped — locked levels must declare 0"
                    )
                continue

            if declared != actual:
                problems.append(
                    f"{where} declares {declared} but {json_name}.json has {actual}"
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
