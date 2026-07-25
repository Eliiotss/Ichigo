"""Catch references to members/types that no longer exist (no Swift compiler here)."""
import pathlib, re, sys
SWIFT_KW = {"return","continue","break","self","true","false","nil","EmptyView","in","try","await"}
src = list(pathlib.Path("Sources/AppFeature").rglob("*.swift"))
problems = []

# 1) AppTheme tokens must exist
theme = pathlib.Path("Sources/AppFeature/AppTheme.swift").read_text(encoding='utf-8')
declared = set(re.findall(r"static (?:let|func|var) ([a-zA-Z_]\w*)", theme))
for f in src:
    for m in re.finditer(r"AppTheme\.([a-zA-Z_]\w*)", f.read_text(encoding='utf-8')):
        if m.group(1) not in declared:
            problems.append(f"{f.name}: AppTheme.{m.group(1)} tidak ada")

# 2) `section("X") { member }` style references must be defined in the same file
for f in src:
    t = f.read_text(encoding='utf-8')
    defined = set(re.findall(r"(?:var|func|let) ([a-zA-Z_]\w*)", t))
    for m in re.finditer(r'section\("[^"]*"\)\s*\{\s*([a-z][a-zA-Z0-9_]*)\s*\}', t):
        if m.group(1) not in defined:
            problems.append(f"{f.name}: '{m.group(1)}' dirujuk tapi tidak didefinisikan")

# 3) project view types referenced must be declared somewhere in the module
declared_types = set()
for f in src:
    declared_types |= set(re.findall(r"^\s*(?:public |private |final )*(?:struct|class|enum) ([A-Z]\w*)",
                                     f.read_text(encoding='utf-8'), re.M))
for f in src:
    t = f.read_text(encoding='utf-8')
    for name in set(re.findall(r"\b(Settings[A-Z]\w*|Screen[A-Z]\w*|SearchField|FilterChipRow|ProfileStatTile|KanjiExampleRow|MenuCardView|ComingSoonView)\s*\(", t)):
        if name not in declared_types:
            problems.append(f"{f.name}: tipe {name} tidak ditemukan")

if problems:
    print("❌ MASALAH:")
    for p in sorted(set(problems)): print("  -", p)
    sys.exit(1)
print("✅ Semua simbol terpenuhi")
