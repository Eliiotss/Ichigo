// Shared inline SVG icons (24×24). Colour is inherited via `currentColor`
// (see the base `svg { fill: currentColor }` rule and per-context overrides in
// styles.css), so the same icon renders white on a gradient chip or tinted in a
// stat tile. Stroke icons (back / chev) rely on their context setting
// `fill: none; stroke: currentColor`. Kept deliberately simple and original.

const P = {
    // Bottom tab bar
    home: '<path d="M12 3.2 3.5 10.5V20a1 1 0 0 0 1 1H9v-6h6v6h4.5a1 1 0 0 0 1-1v-9.5z"/>',
    person: '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm0 1.8c-4.3 0-7.8 2.2-7.8 4.9V21h15.6v-2.3c0-2.7-3.5-4.9-7.8-4.9z"/>',
    gear: '<path d="M19.4 13a7.6 7.6 0 0 0 0-2l2-1.6a.5.5 0 0 0 .12-.62l-1.9-3.3a.5.5 0 0 0-.6-.22l-2.4.96a7 7 0 0 0-1.7-1l-.36-2.5a.48.48 0 0 0-.48-.4h-3.8a.48.48 0 0 0-.48.4l-.36 2.5a7 7 0 0 0-1.7 1l-2.4-.96a.5.5 0 0 0-.6.22l-1.9 3.3a.5.5 0 0 0 .12.62l2 1.6a7.6 7.6 0 0 0 0 2l-2 1.6a.5.5 0 0 0-.12.62l1.9 3.3a.5.5 0 0 0 .6.22l2.4-.96a7 7 0 0 0 1.7 1l.36 2.5a.48.48 0 0 0 .48.4h3.8a.48.48 0 0 0 .48-.4l.36-2.5a7 7 0 0 0 1.7-1l2.4.96a.5.5 0 0 0 .6-.22l1.9-3.3a.5.5 0 0 0-.12-.62zM12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7z"/>',

    // Navigation (stroke)
    back: '<path fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" d="M15 5l-7 7 7 7"/>',
    chev: '<path fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>',
    search: '<path d="M10 2a8 8 0 1 0 4.9 14.32l4.39 4.39 1.42-1.42-4.39-4.39A8 8 0 0 0 10 2zm0 2a6 6 0 1 1 0 12 6 6 0 0 1 0-12z"/>',

    // Menu / mode
    cards: '<path d="M9 5h10a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM5 8v9a4 4 0 0 0 4 4h8v-2H9a2 2 0 0 1-2-2V8z"/>',
    grid: '<path d="M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z"/>',
    info: '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 5a1.3 1.3 0 1 1 0 2.6A1.3 1.3 0 0 1 12 7zm1.2 4v6h-2.4v-6z"/>',
    book: '<path d="M6 3h11a2 2 0 0 1 2 2v15a1 1 0 0 1-1.4.9L12 18.6 6.4 20.9A1 1 0 0 1 5 20V4a1 1 0 0 1 1-1z"/>',

    // Settings / profile
    moon: '<path d="M13 3a9 9 0 1 0 8 13.5A7 7 0 0 1 13 3z"/>',
    bell: '<path d="M12 3a5 5 0 0 0-5 5v3l-1.6 3.1A1 1 0 0 0 6.3 16h11.4a1 1 0 0 0 .9-1.9L17 11V8a5 5 0 0 0-5-5zm0 18a2.3 2.3 0 0 0 2.2-2H9.8A2.3 2.3 0 0 0 12 21z"/>',
    target: '<path fill-rule="evenodd" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 3a7 7 0 1 1 0 14 7 7 0 0 1 0-14zm0 3.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z"/>',
    globe: '<path fill-rule="evenodd" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 2.2c-.9 0-2.3 2.1-2.7 5.3h5.4C14.3 6.3 12.9 4.2 12 4.2zM9.1 11.5c-.1.8-.1 1.6 0 2.4h5.8c.1-.8.1-1.6 0-2.4zm.2 4.6c.5 2.6 1.7 3.7 2.7 3.7s2.2-1.1 2.7-3.7z"/>',
    trash: '<path d="M9 3h6l1 2h4v2H4V5h4zm-3 4h12l-1 12.1A2 2 0 0 1 15 21H9a2 2 0 0 1-2-1.9z"/>',
    cloud: '<path d="M7 18a4.5 4.5 0 0 1-.6-8.96A5.5 5.5 0 0 1 17 9.5 3.75 3.75 0 0 1 17 18z"/>',
    cloudup: '<path d="M12 8l4 4h-2.6v3h-2.8v-3H8zM7 19a4.5 4.5 0 0 1-.6-8.96 5.5 5.5 0 0 1 10.6.46A3.75 3.75 0 0 1 17 19h-1.4l-2-2h.9a1.75 1.75 0 0 0 0-3.5h-1.1l-.2-1A3.5 3.5 0 0 0 8.7 11l-.3.9-.9.1A2.5 2.5 0 0 0 7 17h1.4l-.6-.6 2-2 .1.1V17H7z"/>',
    sync: '<path d="M12 5V2L8 6l4 4V7a5 5 0 1 1-4.9 6h-2A7 7 0 1 0 12 5z"/>',
    signout: '<path d="M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5v-2h5V5h-5zM10.6 8 9.2 9.4 11 11.2H3v2h8l-1.8 1.8 1.4 1.4L15 12z"/>',
    clock: '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm1 5h-2v6l5 3 1-1.7-4-2.3z"/>',
    check: '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm-1.2 14.5-4-4L8.2 11l2.6 2.6L15.8 8l1.4 1.5z"/>',
    flame: '<path d="M13 2c.4 2.5-1 3.9-2 5.3-.9 1.2-1.5 2.2-.6 3.5.5.8 1.7.8 2.3-.1.3-.4.4-1 .3-1.7 1.6 1.2 2.6 3 2.6 5A5.6 5.6 0 0 1 6.4 14c0-2.5 1.4-4 2.6-5.6C10.8 6 12.6 4.4 13 2z"/>',
    star: '<path d="M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9 6.8 19.1l1-5.8L3.5 9.2l5.9-.9z"/>',
    reset: '<path d="M9 3h6l1 2h4v2H4V5h4zm-3 4h12l-1 12.1A2 2 0 0 1 15 21H9a2 2 0 0 1-2-1.9z"/>',
};

// Menu / mode tiles use Japanese glyphs for a clean, thematic look.
export const GLYPH = { huruf: "あ", kanji: "字", vocabulary: "本", grammar: "文", lainnya: "他" };

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
