// Metadata for the iOS-style shell, matching the Claude Design mockup: bottom
// tabs, the Home learning grid (with per-tile icon + gradient), JLPT level info
// per content type, and the flashcard modes. N2/N1 datasets are locked.

export const TABS = [
    { key: "home", label: "Home", icon: "home" },
    { key: "profile", label: "Profile", icon: "person" },
    { key: "settings", label: "Pengaturan", icon: "gear" },
];

// Home "BELAJAR MANDIRI" grid. `glyph` renders a Japanese character; otherwise
// `icon` names an SVG from icons.js.
export const MENU = [
    { id: "huruf", label: "Huruf", sub: "Kana", route: "#/hiragana", glyph: "huruf" },
    { id: "kanji", label: "Kanji", sub: "Aksara", route: "#/kanji", glyph: "kanji" },
    { id: "flashcard", label: "Flashcard", sub: "Review Cepat", route: "#/flashcard", icon: "cards" },
    { id: "vocabulary", label: "Vocabulary", sub: "Kosakata", route: "#/vocab", icon: "bookVocab" },
    { id: "grammar", label: "Grammar", sub: "Tata Bahasa", route: "#/grammar", icon: "bookGrammar" },
    { id: "lainnya", label: "Lainnya", sub: "Fitur Lain", route: "#/soon", icon: "grid" },
];

// English tier names + design descriptions per section. `desc` is a template:
// {n} is replaced by the localized real count.
const TIER = {
    N5: { name: "Beginner", color: "var(--n5)", tint: "var(--n5-tint)" },
    N4: { name: "Elementary", color: "var(--n4)", tint: "var(--n4-tint)" },
    N3: { name: "Intermediate", color: "var(--n3)", tint: "var(--n3-tint)" },
    N2: { name: "Pre-Advanced", color: "var(--n2)", tint: "var(--n2-tint)" },
    N1: { name: "Advanced", color: "var(--n1)", tint: "var(--n1-tint)" },
};

function lv(id, count, file, locked, desc) {
    return { id, name: TIER[id].name, color: TIER[id].color, tint: TIER[id].tint, count, file, locked, desc };
}

export const LEVELS = {
    kanji: [
        lv("N5", 120, "KanjiN5", false, "{n} Essential Kanji"),
        lv("N4", 181, "KanjiN4", false, "{n} Essential Kanji"),
        lv("N3", 367, "KanjiN3", false, "{n} Essential Kanji"),
        lv("N2", null, "KanjiN2", true, "1.000+ Complex Kanji"),
        lv("N1", null, "KanjiN1", true, "2.000+ Master Kanji"),
    ],
    vocab: [
        lv("N5", 800, "VocabN5", false, "{n} Kosakata"),
        lv("N4", 700, "VocabN4", false, "{n} Kosakata"),
        lv("N3", 1800, "VocabN3", false, "{n} Kosakata"),
        lv("N2", null, "VocabN2", true, "Segera hadir"),
        lv("N1", null, "VocabN1", true, "Segera hadir"),
    ],
    grammar: [
        lv("N5", 84, "GrammarN5", false, "{n} Pola tata bahasa"),
        lv("N4", 132, "GrammarN4", false, "{n} Pola tata bahasa"),
        lv("N3", 182, "GrammarN3", false, "{n} Pola tata bahasa"),
        lv("N2", null, "GrammarN2", true, "Segera hadir"),
        lv("N1", null, "GrammarN1", true, "Segera hadir"),
    ],
};

export const SECTION_META = {
    kanji: { label: "Kanji", title: "Kanji", listTitle: "JLPT N5 Kanji", unit: "kanji", searchHint: "Cari Kanji (contoh: 日)" },
    vocab: { label: "Kosakata", title: "Vocabulary", listTitle: "JLPT N5 Vocabulary", unit: "kata", searchHint: "Cari kosakata" },
    grammar: { label: "Tata Bahasa", title: "Grammar", listTitle: "JLPT N5 Grammar", unit: "pola", searchHint: "Cari pola" },
};

// Flashcard modes shown on the type-selection screen.
export const MODES = [
    { type: "vocab", title: "Vocabulary", sub: "Hafalkan kosakata", icon: "cardsFan", grad: "vocabulary-blue" },
    { type: "kanji", title: "Kanji", sub: "Hafalkan aksara", glyph: "kanji", grad: "kanji" },
    { type: "grammar", title: "Grammar", sub: "Hafalkan pola kalimat", icon: "bookGrammarMode", grad: "grammar" },
];

export function findLevel(section, id) {
    return (LEVELS[section] || []).find((l) => l.id === id) || null;
}
