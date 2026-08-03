// Inline SVG icons, taken verbatim from the Claude Design mockup so the web app
// matches it pixel-for-pixel. Colours are baked per the design (white on gradient
// chips, blue/red two-tone detail icons); the tab bar and nav icons use
// `currentColor` so they follow the theme and active state.

const P = {
    // Bottom tab bar (currentColor)
    home: '<path d="M12 3 3 10.5V21h6v-6h6v6h6V10.5L12 3Z"/>',
    person: '<circle cx="12" cy="8" r="4"/><path d="M4 20.5c0-4 3.6-7 8-7s8 3 8 7v.5H4v-.5Z"/>',
    gear: '<path d="M12 8.2a3.8 3.8 0 1 0 0 7.6 3.8 3.8 0 0 0 0-7.6Zm0 2.2a1.6 1.6 0 1 1 0 3.2 1.6 1.6 0 0 1 0-3.2Z"/><path d="M12 1.5l1.4 2.2 2.5-.7.6 2.6 2.6.6-.7 2.5L21 12l-2.2 1.4.7 2.5-2.6.6-.6 2.6-2.5-.7L12 22.5l-1.4-2.2-2.5.7-.6-2.6-2.6-.6.7-2.5L3 12l2.2-1.4-.7-2.5 2.6-.6.6-2.6 2.5.7L12 1.5Z"/>',

    // Nav (currentColor, stroke)
    back: '<path d="M14.5 6 9 12l5.5 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
    chev: '<path d="M9.5 6 15 12l-5.5 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="m15.5 15.5 4 4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',

    // Menu tiles (white on gradient; spine tinted to the tile colour)
    cards: '<rect x="4" y="8" width="16" height="11" rx="2.5" fill="#fff"/><path d="M6 6h12M8 4h8" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" opacity=".7"/>',
    bookVocab: '<path d="M5 5.5A1.5 1.5 0 0 1 6.5 4H18a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H6.5A1.5 1.5 0 0 1 5 18.5V5.5Z" fill="#fff"/><path d="M8 4v16" fill="none" stroke="#0FA8BE" stroke-width="1.4"/>',
    bookGrammar: '<path d="M5 5.5A1.5 1.5 0 0 1 6.5 4H18a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H6.5A1.5 1.5 0 0 1 5 18.5V5.5Z" fill="#fff"/><path d="M10 9h6M10 12h6" fill="none" stroke="#6E5CF0" stroke-width="1.4" stroke-linecap="round"/>',
    grid: '<rect x="4" y="4" width="7" height="7" rx="1.8" fill="#fff"/><rect x="13" y="4" width="7" height="7" rx="1.8" fill="#fff"/><rect x="4" y="13" width="7" height="7" rx="1.8" fill="#fff"/><rect x="13" y="13" width="7" height="7" rx="1.8" fill="#fff"/>',

    // Flashcard mode cards (white on gradient)
    cardsFan: '<path d="M3.5 5.5c2.6-1 5-1 8.5.6 3.5-1.6 5.9-1.6 8.5-.6v13c-2.6-1-5-1-8.5.6-3.5-1.6-5.9-1.6-8.5-.6v-13Z" fill="#fff"/><path d="M12 6.1v13" fill="none" stroke="#2E7BFF" stroke-width="1.4"/>',
    bookGrammarMode: '<path d="M5 5.5A1.5 1.5 0 0 1 6.5 4H18a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H6.5A1.5 1.5 0 0 1 5 18.5V5.5Z" fill="#fff"/><path d="M9.5 8.5h5.5M9.5 11.5h5.5" fill="none" stroke="#6E5CF0" stroke-width="1.5" stroke-linecap="round"/>',

    // Small accents
    info: '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 10.5v6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="12" cy="7.6" r="1.2"/>',
    lock: '<rect x="5" y="10.5" width="14" height="9.5" rx="2.2" fill="currentColor"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" fill="none" stroke="currentColor" stroke-width="1.9"/>',
    speaker: '<path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4v-5Z" fill="currentColor"/><path d="M15.5 9.2a4 4 0 0 1 0 5.6M18 7a7.2 7.2 0 0 1 0 10" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',

    // Profile stat icons (two-tone, baked)
    clock: '<circle cx="12" cy="12" r="9" fill="#2E7BFF"/><path d="M12 7v5l3.5 2" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/>',
    check: '<circle cx="12" cy="12" r="9" fill="#22B981"/><path d="M8 12.5l2.5 2.5L16 9" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>',
    flame: '<path d="M12 3c1 3.5 4.5 4.5 4.5 9a4.5 4.5 0 0 1-9 0c0-2.2 1.2-3.4 2.3-4.4.4 1.2 1.5 1.7 2.2 1.2-1-2.2-1-4.5 0-5.8Z" fill="#FF6B3D"/>',
    star: '<path d="M12 3l2.6 5.6 6.1.7-4.5 4.1 1.2 6L12 16.9 6.6 19.5l1.2-6L3.3 9.3l6.1-.7L12 3Z" fill="#4A55E8"/>',

    // Settings row icons (white on gradient chip)
    user: '<circle cx="12" cy="8" r="3.6" fill="#fff"/><path d="M5 20c0-3.9 3.1-7 7-7s7 3.1 7 7" fill="#fff"/>',
    envelope: '<rect x="3" y="5.5" width="18" height="13" rx="2.5" fill="none" stroke="#fff" stroke-width="2"/><path d="M3.7 7 12 13l8.3-6" fill="none" stroke="#fff" stroke-width="2"/>',
    bell: '<path d="M6 16.5V10a6 6 0 0 1 12 0v6.5l1.5 2h-15l1.5-2Z" fill="#fff"/><path d="M10 19.5a2 2 0 0 0 4 0" fill="none" stroke="#fff" stroke-width="1.6"/>',
    globe: '<circle cx="12" cy="12" r="8.5" fill="none" stroke="#fff" stroke-width="1.8"/><path d="M3.5 12h17M12 3.5c2.6 2.4 2.6 14.6 0 17M12 3.5c-2.6 2.4-2.6 14.6 0 17" fill="none" stroke="#fff" stroke-width="1.5"/>',
    target: '<path d="M4 18l4-10 4 10M5.2 15h5.6M13 8h6M16 8v10M13 18h6" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    trash: '<path d="M4 6.5h16M9 6.5V4.5h6v2M6.5 6.5l1 14h9l1-14" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    cloud: '<path d="M7 18.5a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.7-1.2A3.8 3.8 0 0 1 17 18.5H7Z" fill="none" stroke="#fff" stroke-width="1.8" stroke-linejoin="round"/>',
    cloudTri: '<path d="M12 4 21 19.5H3L12 4Z" fill="none" stroke="#fff" stroke-width="1.8" stroke-linejoin="round"/><path d="M12 10v4.5M12 17.2h.01" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round"/>',

    // Section-card icons (blue/red two-tone, baked)
    arti: '<rect x="4.5" y="4" width="15" height="16" rx="2.5" fill="#2E7BFF"/><path d="M9 9h6M9 12.5h6M9 16h3.5" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/>',
    usage: '<circle cx="6" cy="7" r="1.8" fill="#2E7BFF"/><circle cx="6" cy="12.5" r="1.8" fill="#2E7BFF"/><circle cx="6" cy="18" r="1.8" fill="#2E7BFF"/><path d="M10.5 7h9M10.5 12.5h9M10.5 18h9" fill="none" stroke="#2E7BFF" stroke-width="1.8" stroke-linecap="round"/>',
    warn: '<path d="M12 4 21 19.5H3L12 4Z" fill="none" stroke="#FF3B30" stroke-width="2" stroke-linejoin="round"/><path d="M12 10v4.3M12 17h.01" fill="none" stroke="#FF3B30" stroke-width="2" stroke-linecap="round"/>',
    quotes: '<path d="M5 6h6v6a3 3 0 0 1-3 3H7v-3H5V6ZM13 6h6v6a3 3 0 0 1-3 3h-1v-3h-2V6Z" fill="#2E7BFF"/>',
    xmark: '<circle cx="12" cy="12" r="9" fill="#FF3B30"/><path d="m9 9 6 6M15 9l-6 6" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"/>',

    // Stepper ± (currentColor stroke)
    minus: '<path d="M5 12h14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    plus: '<path d="M12 5v14M5 12h14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
};

// Japanese glyphs used on the Huruf / Kanji tiles (Baloo 2 / system JP).
export const GLYPH = { huruf: "あ", kanji: "字" };

/// Returns SVG markup for a named icon (empty string if unknown).
export function icon(name) {
    const inner = P[name];
    return inner ? `<svg viewBox="0 0 24 24" aria-hidden="true">${inner}</svg>` : "";
}

/// The official multi-colour Google "G", for the sign-in button.
export const GOOGLE_G = `<svg viewBox="0 0 48 48" aria-hidden="true" style="width:18px;height:18px">
<path fill="#4285F4" d="M45.1 24.5c0-1.6-.1-3.1-.4-4.5H24v8.5h11.8c-.5 2.8-2 5.1-4.4 6.7v5.5h7.1c4.1-3.8 6.6-9.4 6.6-16.2z"/>
<path fill="#34A853" d="M24 46c5.9 0 10.9-2 14.5-5.3l-7.1-5.5c-2 1.3-4.5 2.1-7.4 2.1-5.7 0-10.5-3.8-12.2-9H4.5v5.7A22 22 0 0 0 24 46z"/>
<path fill="#FBBC05" d="M11.8 28.3a13.2 13.2 0 0 1 0-8.6v-5.7H4.5a22 22 0 0 0 0 20z"/>
<path fill="#EA4335" d="M24 9.5c3.2 0 6.1 1.1 8.4 3.3l6.3-6.3A22 22 0 0 0 4.5 14l7.3 5.7C13.5 13.3 18.3 9.5 24 9.5z"/>
</svg>`;
