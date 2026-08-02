// Metadata for the iOS-style shell: the three bottom tabs, the Home learning
// menu, JLPT level info per content type, and the flashcard modes. Counts and
// lock states mirror the iOS app; N2/N1 datasets are not shipped yet (locked).

// Bottom tab bar (Home · Profil · Pengaturan), like the iOS TabView.
export const TABS = [
    { key: "home", label: "Home", icon: "home" },
    { key: "profile", label: "Profil", icon: "person" },
    { key: "settings", label: "Pengaturan", icon: "gear" },
];

// Home "BELAJAR MANDIRI" grid — same six tiles as ContentView.swift.
export const MENU = [
    { id: "huruf", label: "Huruf", sub: "Kana", route: "#/hiragana", icon: "kana" },
    { id: "kanji", label: "Kanji", sub: "Aksara", route: "#/kanji", icon: "kanji" },
    { id: "flashcard", label: "Flashcard", sub: "Review Cepat", route: "#/flashcard", icon: "cards" },
    { id: "vocabulary", label: "Vocabulary", sub: "Kosakata", route: "#/vocab", icon: "book" },
    { id: "grammar", label: "Grammar", sub: "Tata Bahasa", route: "#/grammar", icon: "grammar" },
    { id: "lainnya", label: "Lainnya", sub: "Fitur Lain", route: "#/soon", icon: "grid" },
];

const LV = { N5: "var(--n5)", N4: "var(--n4)", N3: "var(--n3)", N2: "var(--n2)", N1: "var(--n1)" };

// tier name + short description per level, matching the app's level cards.
const TIER = {
    N5: { name: "Pemula", desc: "Dasar mutlak untuk memulai" },
    N4: { name: "Dasar", desc: "Materi sehari-hari" },
    N3: { name: "Menengah", desc: "Lompatan ke tingkat menengah" },
    N2: { name: "Pra-Mahir", desc: "Segera hadir" },
    N1: { name: "Mahir", desc: "Segera hadir" },
};

function lv(id, count, file, locked) {
    return { id, name: TIER[id].name, desc: TIER[id].desc, count, file, locked, color: LV[id] };
}

export const LEVELS = {
    kanji: [
        lv("N5", 120, "KanjiN5", false),
        lv("N4", 181, "KanjiN4", false),
        lv("N3", 367, "KanjiN3", false),
        lv("N2", null, "KanjiN2", true),
        lv("N1", null, "KanjiN1", true),
    ],
    vocab: [
        lv("N5", 800, "VocabN5", false),
        lv("N4", 700, "VocabN4", false),
        lv("N3", 1800, "VocabN3", false),
        lv("N2", null, "VocabN2", true),
        lv("N1", null, "VocabN1", true),
    ],
    grammar: [
        lv("N5", 84, "GrammarN5", false),
        lv("N4", 132, "GrammarN4", false),
        lv("N3", 182, "GrammarN3", false),
        lv("N2", null, "GrammarN2", true),
        lv("N1", null, "GrammarN1", true),
    ],
};

export const SECTION_META = {
    kanji: { label: "Kanji", title: "Kanji", unit: "kanji", icon: "kanji" },
    vocab: { label: "Kosakata", title: "Kosakata", unit: "kata", icon: "book" },
    grammar: { label: "Tata Bahasa", title: "Tata Bahasa", unit: "pola", icon: "grammar" },
};

// Flashcard modes shown on the type-selection screen.
export const MODES = [
    { type: "vocab", title: "Kosakata", sub: "Kartu kata & arti", icon: "book", grad: "vocabulary" },
    { type: "kanji", title: "Kanji", sub: "Aksara & bacaan", icon: "kanji", grad: "kanji" },
    { type: "grammar", title: "Tata Bahasa", sub: "Pola & makna", icon: "grammar", grad: "grammar" },
];

export function findLevel(section, id) {
    return (LEVELS[section] || []).find((l) => l.id === id) || null;
}
