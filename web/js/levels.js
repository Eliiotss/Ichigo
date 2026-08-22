// Metadata for the iOS-style design: sidebar/tab nav lives in app.js; here are
// the Home learning grid, JLPT level info per content type (colours from the
// Claude Design mockup), and the flashcard modes. All five tiers (N5–N1) now
// ship real datasets, synced to the Android app's counts; none stays locked.

/// rgba() from a #RRGGBB hex + alpha (for tinted chips/backgrounds).
export function alpha(hex, a) {
    const n = parseInt(hex.slice(1), 16);
    return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

// Home "BELAJAR MANDIRI" grid — glyph tiles with per-tile gradients.
export const MENU = [
    { id: "huruf", label: "Huruf", sub: "Kana", glyph: "あ", grad: "linear-gradient(135deg,#FF9500,#E66619)", route: "#/hiragana" },
    { id: "kanji", label: "Kanji", sub: "Aksara", glyph: "漢", grad: "linear-gradient(135deg,#AF52DE,#801AE6)", route: "#/kanji" },
    { id: "flashcard", label: "Flashcard", sub: "Review Cepat", glyph: "札", grad: "linear-gradient(135deg,#FF2D55,#E63366)", route: "#/flashcard" },
    { id: "vocabulary", label: "Vocabulary", sub: "Kosakata", glyph: "語", grad: "linear-gradient(135deg,#2E7BFF,#1A5FD6)", route: "#/vocab" },
    { id: "grammar", label: "Grammar", sub: "Tata Bahasa", glyph: "文", grad: "linear-gradient(135deg,#34C759,#1AB380)", route: "#/grammar" },
    { id: "lainnya", label: "Lainnya", sub: "Fitur Lain", glyph: "他", grad: "linear-gradient(135deg,#8E8E93,#4D4D66)", route: "#/soon" },
];

const TIER = {
    N5: { name: "Beginner", desc: "Dasar — pemula mutlak", color: "#34C759" },
    N4: { name: "Elementary", desc: "Dasar lanjutan", color: "#2E7BFF" },
    N3: { name: "Intermediate", desc: "Menengah", color: "#FF9500" },
    N2: { name: "Pre-Advanced", desc: "Menengah atas", color: "#AF52DE" },
    N1: { name: "Advanced", desc: "Mahir", color: "#FF3B30" },
};

function lv(id, count, file, locked) {
    return { id, name: TIER[id].name, desc: TIER[id].desc, color: TIER[id].color, count, file, locked };
}

export const LEVELS = {
    kanji: [
        lv("N5", 142, "KanjiN5", false), lv("N4", 269, "KanjiN4", false), lv("N3", 594, "KanjiN3", false),
        lv("N2", 612, "KanjiN2", false), lv("N1", 305, "KanjiN1", false),
    ],
    vocab: [
        lv("N5", 1087, "VocabN5", false), lv("N4", 1015, "VocabN4", false), lv("N3", 2642, "VocabN3", false),
        lv("N2", 2122, "VocabN2", false), lv("N1", 1011, "VocabN1", false),
    ],
    grammar: [
        lv("N5", 87, "GrammarN5", false), lv("N4", 137, "GrammarN4", false), lv("N3", 191, "GrammarN3", false),
        lv("N2", 155, "GrammarN2", false), lv("N1", 104, "GrammarN1", false),
    ],
};

export const SECTION_META = {
    kanji: { label: "Kanji", unit: "kanji", searchHint: "Cari Kanji (contoh: 日)" },
    vocab: { label: "Vocabulary", unit: "kosakata", searchHint: "Cari kosakata" },
    grammar: { label: "Grammar", unit: "pola", searchHint: "Cari tata bahasa..." },
};

export const MODES = [
    { type: "vocab", title: "Vocabulary", sub: "Kosakata JLPT", glyph: "語", color: "#2E7BFF" },
    { type: "kanji", title: "Kanji", sub: "Aksara JLPT", glyph: "漢", color: "#AF52DE" },
    { type: "grammar", title: "Grammar", sub: "Pola tata bahasa", glyph: "文", color: "#34C759" },
];

export function findLevel(section, id) {
    return (LEVELS[section] || []).find((l) => l.id === id) || null;
}
