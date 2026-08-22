#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rapikan ekspor Anki (banyak notetype) -> tabel Markdown materi bersih:
   | Kata | Bacaan | Arti | Contoh |
Ambil MATERINYA saja (tanpa guid/HTML/audio/kolom teknis). Peta kolom per
notetype supaya akurat lintas deck. Dedup (kata+bacaan). Kartu info/sambutan
dilewati."""
import sys, re, html, collections

SRC = sys.argv[1]
DST = sys.argv[2] if len(sys.argv) > 2 else "materi.md"

# Peta kolom absolut (1-indexed) per notetype: (kata, bacaan_src, arti, contoh)
# bacaan_src boleh berisi furigana; nanti diubah ke bacaan kana bersih.
MAPS = {
    "Japanese sentences+": (4, 9, 12, 5),
    "Mining-JP":           (4, 6, 13, 9),
    "Modifikasi JP1K":     (4, 5, 10, 8),
}
DEFAULT = (4, 5, 6, 9)          # Kaishi, Tango, Kotoba, B Jepang, dll.
SKIP_NT = {"Ankidrone Info"}    # kartu info, bukan kosakata
KANJI = r"[㐀-鿿々〆ヶ]"

def base_common(s):
    s = (s or "").strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':   # buka escape TSV
        s = s[1:-1].replace('""', '"')
    s = re.sub(r"\[sound:[^\]]*\]", "", s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = html.unescape(s).replace(" ", " ").replace("　", " ")
    return re.sub(r"[ \t]+", " ", s).strip()

def kata_of(s):                          # buang furigana [..] -> kata dasar
    return base_common(re.sub(r"\[[^\]]*\]", "", s or ""))

def reading_of(s):                       # furigana/kanji -> bacaan kana bersih
    s = base_common(s)
    s = re.sub(KANJI + r"*\[([^\]]+)\]", r"\1", s)   # 漢字[かな] -> かな
    # sisakan hanya kana (buang catatan Inggris/tanda kurung/spasi yang bocor)
    return "".join(ch for ch in s if re.match(r"[ぁ-ゖァ-ヺーゝ-ゟ・]", ch))

def example_of(s):                       # kalimat contoh: furigana -> (bacaan)
    s = base_common(s)
    s = re.sub(r"(" + KANJI + r"+)\[([^\]]+)\]", r"\1(\2)", s)
    return s.replace("|", "\\|").strip()

def arti_of(s):                          # "English  Indonesian" -> ambil ID
    s = base_common(s)
    parts = re.split(r"\s{2,}", s)
    s = parts[-1] if len(parts) > 1 else s
    return s.replace("|", "\\|").strip()

def cell(s):
    return base_common(s).replace("|", "\\|")

# --- baca header ---
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

seen, out, stats = set(), [], collections.Counter()
for r in rows:
    nt = col(r, notetype_col)
    if nt in SKIP_NT:
        continue
    deck = col(r, deck_col)
    if "Bunpou" in deck or "文法" in deck:   # pola tata bahasa -> ke grammar.md
        continue
    kmap = None
    for key, mp in MAPS.items():
        if key in nt:
            kmap = mp; break
    ci, bi, ai, ei = kmap or DEFAULT
    kata   = cell(kata_of(col(r, ci))).replace("|", "\\|")
    bacaan = reading_of(col(r, bi))
    arti   = arti_of(col(r, ai))
    contoh = example_of(col(r, ei))
    # saring: harus ada kata+bacaan+arti; kata bukan kalimat panjang / info
    if not (kata and bacaan and arti):
        continue
    if len(kata) > 20 or "\n" in kata:
        continue
    key = (kata, bacaan)
    if key in seen:
        continue
    seen.add(key)
    out.append((kata, bacaan, arti, contoh))
    stats[nt] += 1

with open(DST, "w", encoding="utf-8") as f:
    f.write(f"# Materi Kosakata ({len(out)} kata)\n\n")
    f.write("| Kata | Bacaan | Arti | Contoh |\n|---|---|---|---|\n")
    for k, b, a, c in out:
        f.write(f"| {k} | {b} | {a} | {c} |\n")

print(f"UNIK: {len(out)} kata -> {DST}")
print("Per notetype (yang diambil):")
for nt, c in stats.most_common():
    print(f"  {c:>6}  {nt}")
