"""Static consistency checks for the SwiftUI sources.

This environment has no Swift compiler, so these checks stand in for the errors
Xcode would surface: missing AppTheme tokens, references to view members that no
longer exist, and — the subtle one — a struct using `colorScheme` without
declaring `@Environment(\\.colorScheme)`, where Swift silently resolves the name
to SwiftUI's `View.colorScheme(_:)` modifier instead.
"""
import pathlib, re, sys

SRC = list(pathlib.Path("Sources/AppFeature").rglob("*.swift"))
problems: list[str] = []

# 1) Every AppTheme.<token> must be declared in AppTheme.swift
theme = pathlib.Path("Sources/AppFeature/AppTheme.swift").read_text(encoding="utf-8")
declared = set(re.findall(r"static (?:let|func|var) ([a-zA-Z_]\w*)", theme))
for f in SRC:
    for m in re.finditer(r"AppTheme\.([a-zA-Z_]\w*)", f.read_text(encoding="utf-8")):
        if m.group(1) not in declared:
            problems.append(f"{f.name}: AppTheme.{m.group(1)} tidak ada")

# 2) Per-struct: using `colorScheme` / `scheme` requires the matching @Environment
TYPE_RE = re.compile(r"^\s*(?:public |private |final )*(?:struct|class) (\w+)", re.M)
for f in SRC:
    text = f.read_text(encoding="utf-8")
    marks = [(m.start(), m.group(1)) for m in TYPE_RE.finditer(text)]
    for i, (start, name) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(text)
        body = text[start:end]
        for var in ("colorScheme", "scheme"):
            uses = re.search(rf"AppTheme\.\w+\({var}\)", body)
            if uses and not re.search(rf"@Environment\(\\\.colorScheme\)[^\n]*\b{var}\b", body):
                problems.append(f"{f.name}: struct {name} memakai '{var}' tanpa @Environment(\\.colorScheme)")

# 3) `section("X") { member }` references must be defined in the same file
for f in SRC:
    text = f.read_text(encoding="utf-8")
    defined = set(re.findall(r"(?:var|func|let) ([a-zA-Z_]\w*)", text))
    for m in re.finditer(r'section\("[^"]*"\)\s*\{\s*([a-z][a-zA-Z0-9_]*)\s*\}', text):
        if m.group(1) not in defined:
            problems.append(f"{f.name}: '{m.group(1)}' dirujuk tapi tidak didefinisikan")

# 4) Project view types referenced must exist somewhere in the module
declared_types: set[str] = set()
for f in SRC:
    declared_types |= set(TYPE_RE.findall(f.read_text(encoding="utf-8")))
    declared_types |= set(re.findall(r"^\s*enum (\w+)", f.read_text(encoding="utf-8"), re.M))
CUSTOM = re.compile(r"\b(Settings[A-Z]\w*|Screen[A-Z]\w*|SearchField|FilterChipRow|ProfileStatTile|KanjiExampleRow|MenuCardView|ComingSoonView|Grammar[A-Z]\w*|Kana[A-Z]\w*)\s*\(")
for f in SRC:
    for name in set(CUSTOM.findall(f.read_text(encoding="utf-8"))):
        if name not in declared_types:
            problems.append(f"{f.name}: tipe {name} tidak ditemukan")

if problems:
    print("❌ MASALAH:")
    for p in sorted(set(problems)):
        print("  -", p)
    sys.exit(1)
print("✅ Semua pemeriksaan simbol lolos")
