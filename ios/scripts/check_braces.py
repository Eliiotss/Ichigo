#!/usr/bin/env python3
"""Verify that every Swift source file has balanced brackets.

An unbalanced brace is the failure mode that produces the least helpful
compiler diagnostics — Swift reports the error at the end of the file rather
than at the edit that caused it. Catching it here gives an exact filename in
seconds, before the (much slower) simulator build runs.

The scanner is Swift-aware: it skips line and block comments, single-line and
multi-line string bodies, and it re-enters string mode at the closing paren of
a ``\\(...)`` interpolation, so brackets that appear inside string literals are
never counted.
"""

from __future__ import annotations

import pathlib
import sys

PAIRS = (("{", "}"), ("(", ")"), ("[", "]"))
SOURCE_ROOTS = ("Sources", "Tests")


def count_brackets(src: str) -> dict[str, int]:
    """Count brackets that appear in code, ignoring comments and string bodies."""
    counts = {char: 0 for pair in PAIRS for char in pair}
    # Frames are ["code", None], ["str", is_multiline] or ["interp", paren_depth].
    stack: list[list] = [["code", None]]
    i, n = 0, len(src)

    while i < n:
        char = src[i]
        frame = stack[-1]

        if frame[0] in ("code", "interp"):
            if src.startswith("//", i):
                newline = src.find("\n", i)
                i = n if newline < 0 else newline
                continue
            if src.startswith("/*", i):
                end = src.find("*/", i + 2)
                i = n if end < 0 else end + 2
                continue
            if src.startswith('"""', i):
                stack.append(["str", True])
                i += 3
                continue
            if char == '"':
                stack.append(["str", False])
                i += 1
                continue

            if char in counts:
                counts[char] += 1

            # Inside an interpolation, the paren that closes it ends the
            # expression and returns the scanner to the enclosing string.
            if frame[0] == "interp":
                if char == "(":
                    frame[1] += 1
                elif char == ")":
                    if frame[1] == 0:
                        stack.pop()
                    else:
                        frame[1] -= 1
            i += 1
            continue

        # Inside a string body.
        if char == "\\" and i + 1 < n:
            if src[i + 1] == "(":
                counts["("] += 1
                stack.append(["interp", 0])
                i += 2
                continue
            i += 2  # any other escape sequence
            continue
        if frame[1] and src.startswith('"""', i):
            stack.pop()
            i += 3
            continue
        if not frame[1] and char in ('"', "\n"):
            stack.pop()  # closing quote, or an unterminated single-line string
            i += 1
            continue
        i += 1

    return counts


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    problems: list[str] = []
    checked = 0

    for source_root in SOURCE_ROOTS:
        for path in sorted((root / source_root).rglob("*.swift")):
            checked += 1
            counts = count_brackets(path.read_text(encoding="utf-8"))
            for opener, closer in PAIRS:
                if counts[opener] != counts[closer]:
                    problems.append(
                        f"{path.relative_to(root)}: {counts[opener]} '{opener}' "
                        f"vs {counts[closer]} '{closer}'"
                    )

    if problems:
        print("❌ Kurung tidak seimbang:")
        for problem in problems:
            print(f"   - {problem}")
        return 1

    print(f"✅ Kurung seimbang di {checked} berkas Swift")
    return 0


if __name__ == "__main__":
    sys.exit(main())
