// Level metadata for the three JLPT content types. Counts and lock states mirror
// the iOS app's models; N2/N1 datasets are not shipped yet (locked).

export const SECTIONS = [
    { key: "home", label: "Beranda" },
    { key: "kanji", label: "Kanji" },
    { key: "vocab", label: "Kosakata" },
    { key: "grammar", label: "Tata Bahasa" },
    { key: "hiragana", label: "Hiragana" },
    { key: "flashcard", label: "Flashcard" },
];

const LV = { N5: "var(--n5)", N4: "var(--n4)", N3: "var(--n3)", N2: "var(--n2)", N1: "var(--n1)" };

function lv(id, name, count, file, locked) {
    return { id, name, count, file, locked, color: LV[id] };
}

export const LEVELS = {
    kanji: [
        lv("N5", "Pemula", 120, "KanjiN5", false),
        lv("N4", "Dasar", 181, "KanjiN4", false),
        lv("N3", "Menengah", 367, "KanjiN3", false),
        lv("N2", "Pra-Mahir", null, "KanjiN2", true),
        lv("N1", "Mahir", null, "KanjiN1", true),
    ],
    vocab: [
        lv("N5", "Pemula", 800, "VocabN5", false),
        lv("N4", "Dasar", 700, "VocabN4", false),
        lv("N3", "Menengah", 1800, "VocabN3", false),
        lv("N2", "Pra-Mahir", null, "VocabN2", true),
        lv("N1", "Mahir", null, "VocabN1", true),
    ],
    grammar: [
        lv("N5", "Pemula", 84, "GrammarN5", false),
        lv("N4", "Dasar", 132, "GrammarN4", false),
        lv("N3", "Menengah", 182, "GrammarN3", false),
        lv("N2", "Pra-Mahir", null, "GrammarN2", true),
        lv("N1", "Mahir", null, "GrammarN1", true),
    ],
};

export const SECTION_META = {
    kanji: { label: "Kanji", emoji: "🈶", unit: "kanji" },
    vocab: { label: "Kosakata", emoji: "📖", unit: "kata" },
    grammar: { label: "Tata Bahasa", emoji: "📝", unit: "pola" },
};

export function findLevel(section, id) {
    return (LEVELS[section] || []).find((l) => l.id === id) || null;
}
