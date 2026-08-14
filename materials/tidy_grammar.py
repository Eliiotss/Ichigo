#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rapikan pola TATA BAHASA (deck Bunpou) dari ekspor Anki -> tabel Markdown:
   | Level | Pola | Penjelasan | Contoh | Arti |
Ambil materinya saja (buang guid/HTML/audio/sumber teknis). Furigana pada
Contoh dipertahankan sebagai kata(bacaan). Dedup per pola."""
import sys, re, html, collections

SRC = sys.argv[1]
DST = sys.argv[2] if len(sys.argv) > 2 else "grammar.md"
KANJI = r"[㐀-鿿々〆ヶ]"

def unquote(s):                          # buka escape gaya TSV: "...""..." -> ..."...
    s = (s or "").strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        s = s[1:-1].replace('""', '"')
    return s

def clean(s):
    s = unquote(s)
    s = re.sub(r"\[sound:[^\]]*\]", "", s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = html.unescape(s).replace(" ", " ").replace("　", " ")
    return re.sub(r"[ \t]+", " ", s).strip()

def cell(s):
    return clean(s).strip('"').replace("|", "\\|").strip()

def example(s):
    s = clean(s)
    s = re.sub(r"(" + KANJI + r"+)\[([^\]]+)\]", r"\1(\2)", s)
    return s.replace("|", "\\|").strip()

notetype_col = deck_col = tags_col = None
rows = []
with open(SRC, encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.rstrip("\n")
        if line.startswith("#"):
            m = re.match(r"#(\w+) column:(\d+)", line)
            if m:
                k, i = m.group(1), int(m.group(2))
                if k == "notetype": notetype_col = i
                elif k == "deck": deck_col = i
                elif k == "tags": tags_col = i
            continue
        if line.strip():
            rows.append(line.split("\t"))

def col(r, i):
    return r[i-1] if (i and 0 < i <= len(r)) else ""

LEVEL_ORDER = {"N5": 0, "N4": 1, "N3": 2, "N2": 3, "N1": 4}
seen, out = set(), []
for r in rows:
    deck = col(r, deck_col)
    if "Bunpou" not in deck and "文法" not in deck:
        continue
    m = re.search(r"JLPT (N[1-5])", deck)   # level dari subdeck "::JLPT N5 (...)"
    level = m.group(1) if m else "-"
    pola = cell(col(r, 4))
    penjelasan = cell(col(r, 7))
    contoh = example(col(r, 9) or col(r, 8))
    arti = cell(col(r, 10))
    if not pola:
        continue
    if pola in seen:
        continue
    seen.add(pola)
    out.append((level, pola, penjelasan, contoh, arti))

out.sort(key=lambda x: LEVEL_ORDER.get(x[0], 9))
with open(DST, "w", encoding="utf-8") as f:
    f.write(f"# Tata Bahasa / Grammar ({len(out)} pola)\n\n")
    f.write("| Level | Pola | Penjelasan | Contoh | Arti |\n|---|---|---|---|---|\n")
    for lv, p, pen, c, a in out:
        f.write(f"| {lv} | {p} | {pen} | {c} | {a} |\n")

by = collections.Counter(x[0] for x in out)
print(f"UNIK: {len(out)} pola -> {DST}")
print("Per level:", dict(sorted(by.items(), key=lambda kv: LEVEL_ORDER.get(kv[0], 9))))
