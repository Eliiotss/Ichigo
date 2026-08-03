// Content browser, matching the Claude Design mockup: Home (greeting + hero
// progress + learning grid), level pickers (English tiers), searchable lists
// (kanji grid, vocab & grammar cards + filter chips), detail pages (blue hero +
// section cards), and the Hiragana/Katakana chart. Audio uses the browser's
// speech synthesis (ja-JP) — a real feature, no placeholder.

import { loadJSON } from "./data.js";
import { LEVELS, SECTION_META, MENU, findLevel } from "./levels.js";
import { icon, GLYPH } from "./icons.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const route = (...parts) => "#/" + parts.filter(Boolean).join("/");

export function speak(text) {
    try {
        if (!window.speechSynthesis) return;
        const u = new SpeechSynthesisUtterance(String(text || ""));
        u.lang = "ja-JP";
        speechSynthesis.cancel();
        speechSynthesis.speak(u);
    } catch { /* unsupported */ }
}
// Delegate speaker-button clicks (works after every re-render).
document.addEventListener("click", (e) => {
    const b = e.target.closest("[data-speak]");
    if (b) { e.preventDefault(); speak(b.getAttribute("data-speak")); }
});

function screenHeader(title, backHref, small) {
    return `<div class="screen-header">
        <a class="back-btn" href="${backHref}" aria-label="Kembali">${icon("back")}</a>
        <h1 class="screen-title${small ? " small" : ""}">${esc(title)}</h1>
    </div>`;
}

function initials(name) {
    const w = String(name || "").trim().split(/\s+/).filter(Boolean);
    if (!w.length) return "U";
    return (w.length > 1 ? w[0][0] + w[1][0] : w[0].slice(0, 2)).toUpperCase();
}

// ---------- Home ----------

export function renderHome(app) {
    const name = store.getUsername() || "Teman";
    const target = store.getDailyTarget();
    const studied = store.studiedTodayTotal();
    const progress = target > 0 ? Math.min(studied / target, 1) : 0;
    const due = store.dueTodayTotal(target);
    const streak = store.getStreak().count;
    const mastered = store.masteredTotal();

    const tile = (m) => {
        const inner = m.glyph ? esc(GLYPH[m.glyph]) : icon(m.icon);
        return `<a class="menu-card" href="${m.route}">
            <span class="menu-icon ${m.id}">${inner}</span>
            <span class="menu-label">${esc(m.label)}</span>
            <span class="menu-sub">${esc(m.sub)}</span>
        </a>`;
    };

    app.innerHTML = `
        <div class="greeting">
            <div>
                <div class="greeting-kicker">Okaeri 🍓</div>
                <div class="greeting-name">Halo, ${esc(name)}</div>
            </div>
            <a class="avatar" href="${route("profile")}" aria-label="Buka profil">${esc(initials(name))}</a>
        </div>

        <div class="hero">
            <div class="hero-top"><span class="label">PROGRESS HARI INI</span><span class="count">${studied}/${target}</span></div>
            <div class="hero-bar"><span style="width:${Math.max(progress * 100, progress > 0 ? 4 : 0)}%"></span></div>
            <div class="hero-stats">
                <div class="hero-stat"><div class="v">${due}</div><div class="l">Due</div></div>
                <div class="hero-stat"><div class="v">🔥 ${streak}</div><div class="l">Streak</div></div>
                <div class="hero-stat"><div class="v">${mastered}</div><div class="l">Mastered</div></div>
            </div>
        </div>

        <div class="section-label">BELAJAR MANDIRI</div>
        <div class="menu-grid">${MENU.map(tile).join("")}</div>`;
}

// ---------- Level picker ----------

export function renderLevels(app, section) {
    const meta = SECTION_META[section];
    const levels = LEVELS[section] || [];
    app.innerHTML = screenHeader(meta.title, route("home")) +
        `<div class="level-list">${levels.map((l) => levelCard(section, l)).join("")}</div>`;
}

function levelCard(section, l) {
    const desc = esc(l.desc.replace("{n}", (l.count || 0).toLocaleString("id-ID")));
    if (l.locked) {
        return `<div class="level-card locked">
            <span class="level-chip" style="background:${l.tint};color:${l.color}">${l.id}</span>
            <span class="level-main"><span class="level-name" style="color:var(--muted)">${esc(l.name)}</span><span class="level-desc">${desc}</span></span>
            <span class="lock-badge">${icon("lock")} Terkunci</span>
        </div>`;
    }
    return `<a class="level-card" href="${route(section, l.id)}">
        <span class="level-chip" style="background:${l.tint};color:${l.color}">${l.id}</span>
        <span class="level-main"><span class="level-name">${esc(l.name)}</span><span class="level-desc">${desc}</span></span>
        <span class="chev">${icon("chev")}</span>
    </a>`;
}

// ---------- Lists ----------

export async function renderList(app, section, levelId) {
    const level = findLevel(section, levelId);
    if (!level || level.locked) return renderLevels(app, section);
    const meta = SECTION_META[section];
    app.innerHTML =
        screenHeader(`JLPT ${level.id} ${meta.title}`, route(section), true) +
        `<div class="search-field">${icon("search")}
            <input id="search" type="search" placeholder="${esc(meta.searchHint)}" autocomplete="off" spellcheck="false"></div>
        <div id="filterRow"></div>
        <div id="listBox"><div class="loading">Memuat…</div></div>`;

    let items;
    try {
        items = await loadJSON(level.file);
    } catch (e) {
        document.getElementById("listBox").innerHTML =
            `<div class="empty-state">${esc(e.message)}<br>Jalankan lewat server (mis. <code>python3 -m http.server</code>).</div>`;
        return;
    }

    const box = document.getElementById("listBox");
    const search = document.getElementById("search");
    let filter = "Semua";

    // Vocab gets word-type filter chips (like the design).
    if (section === "vocab") {
        const types = ["Semua", ...Array.from(new Set(items.map((it) => it.jenisKata).filter(Boolean)))];
        const drawChips = () => {
            document.getElementById("filterRow").innerHTML =
                `<div class="chip-row">${types.map((t) =>
                    `<button class="chip ${t === filter ? "active" : ""}" data-filter="${esc(t)}">${esc(t)}</button>`).join("")}</div>`;
            document.querySelectorAll("[data-filter]").forEach((b) =>
                b.addEventListener("click", () => { filter = b.dataset.filter; drawChips(); draw(search.value); }));
        };
        drawChips();
    }

    const renderer = { kanji: kanjiCards, vocab: vocabCards, grammar: grammarCards }[section];
    const matcher = { kanji: kanjiMatch, vocab: vocabMatch, grammar: grammarMatch }[section];
    const draw = (q) => {
        const query = q.trim().toLowerCase();
        let shown = query ? items.filter((it) => matcher(it, query)) : items;
        if (section === "vocab" && filter !== "Semua") shown = shown.filter((it) => it.jenisKata === filter);
        box.innerHTML = shown.length
            ? renderer(shown, section, level.id)
            : `<div class="empty-state">Tidak ada hasil.</div>`;
    };
    draw("");
    let t;
    search.addEventListener("input", () => { clearTimeout(t); t = setTimeout(() => draw(search.value), 120); });
}

function kanjiCards(items, section, lvl) {
    return `<div class="card-grid">${items.map((it) => `
        <a class="kentry" href="${route(section, lvl, it.id)}">
            <span class="jp">${esc(it.kanji)}</span>
            <span class="reading">${esc(it.onyomi || it.kunyomi || "")}</span>
            <span class="meaning">${esc(it.meaning)}</span>
        </a>`).join("")}</div>`;
}
const kanjiMatch = (it, q) =>
    (it.kanji || "").includes(q) || (it.meaning || "").toLowerCase().includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) || (it.onyomi || "").toLowerCase().includes(q) ||
    (it.kunyomi || "").toLowerCase().includes(q);

function vocabCards(items, section, lvl) {
    return `<div class="vlist">${items.map((it) => `
        <div class="vcard">
            <div>
                <span class="jlpt-badge">JLPT ${esc(lvl)}</span>
                <div class="v-kanji">${esc(it.kanji)}</div>
                <div class="v-kana">${esc(it.hiragana)}</div>
                ${it.jenisKata ? `<div class="v-type">${esc(it.jenisKata)}</div>` : ""}
                <div class="v-mean">${esc(it.arti)}</div>
            </div>
            <button class="speak-circle" data-speak="${esc(it.kanji || it.hiragana)}" aria-label="Dengarkan">${icon("speaker")}</button>
        </div>`).join("")}</div>`;
}
const vocabMatch = (it, q) =>
    (it.kanji || "").includes(q) || (it.hiragana || "").includes(q) || (it.arti || "").toLowerCase().includes(q);

function grammarCards(items, section, lvl) {
    return `<div class="glist">${items.map((it) => `
        <a class="gcard" href="${route(section, lvl, it.id)}">
            <div class="g-top"><span class="jlpt-badge ghost">JLPT ${esc(lvl)}</span>${it.treeCategory ? `<span class="g-cat">${esc(it.treeCategory)}</span>` : ""}</div>
            <div class="g-pattern">${esc(it.pattern)}</div>
            <div class="g-romaji">${esc(it.romaji)}</div>
            <div class="g-mean">${esc(it.meaning)}</div>
        </a>`).join("")}</div>`;
}
const grammarMatch = (it, q) =>
    (it.pattern || "").includes(q) || (it.romaji || "").toLowerCase().includes(q) || (it.meaning || "").toLowerCase().includes(q);

// ---------- Detail ----------

const DETAIL_TITLE = { kanji: "Detail Kanji", vocab: "Detail Kosakata", grammar: "Detail Grammar" };

export async function renderDetail(app, section, levelId, id) {
    const level = findLevel(section, levelId);
    if (!level) return renderLevels(app, section);
    let items;
    try { items = await loadJSON(level.file); }
    catch (e) { app.innerHTML = `<div class="empty-state">${esc(e.message)}</div>`; return; }
    const it = items.find((x) => x.id === id);
    if (!it) return renderList(app, section, levelId);
    const body = { kanji: kanjiDetail, vocab: vocabDetail, grammar: grammarDetail }[section](it, level);
    app.innerHTML = screenHeader(DETAIL_TITLE[section], route(section, levelId), true) + `<div class="detail-stack">${body}</div>`;
}

function sectionCard(title, iconName, inner, opts = {}) {
    return `<div class="section-card">
        <div class="section-card-head">
            <span class="section-card-icon ${opts.warn ? "warn" : ""}">${icon(iconName)}</span>
            <span class="section-card-title">${esc(title)}</span>
            ${opts.count ? `<span class="section-card-count">${esc(opts.count)}</span>` : ""}
        </div>${inner}</div>`;
}

function kanjiDetail(it, level) {
    const examples = (it.examples || []).map((ex) => `
        <div class="example">
            <div style="display:flex;justify-content:space-between;gap:10px">
                <div>
                    <span class="ex-word">${esc(ex.word)}</span> <span class="ex-reading">（${esc(ex.reading)}）</span>
                    <div class="ex-gloss">${esc(ex.romaji)} — ${esc(ex.meaning)}</div>
                </div>
                <button class="speak-circle" data-speak="${esc(ex.sentence || ex.word)}" aria-label="Dengarkan">${icon("speaker")}</button>
            </div>
            ${(ex.sentenceFurigana || ex.sentence) ? `<div style="background:var(--soft);border-radius:14px;padding:11px 13px;margin-top:11px">
                <div class="ex-sentence" style="margin-top:0">${esc(ex.sentenceFurigana || ex.sentence)}</div>
                ${ex.sentenceMeaning ? `<div class="ex-trans">${esc(ex.sentenceMeaning)}</div>` : ""}</div>` : ""}
        </div>`).join("");

    return `
        <div class="detail-hero">
            <div class="hero-badges"><span class="hero-badge">JLPT ${esc(level.id)}</span>
                <button class="speak-circle" style="background:rgba(255,255,255,.22);color:#fff" data-speak="${esc(it.kanji)}" aria-label="Dengarkan">${icon("speaker")}</button></div>
            <div class="hero-glyph">${esc(it.kanji)}</div>
            <div class="hero-romaji">${esc(it.romaji)}</div>
            <div class="hero-sub">${esc(it.meaning)}</div>
        </div>
        <div class="reading-cards">
            <div class="reading-card"><div class="rc-label">ONYOMI</div><div class="rc-value">${esc(it.onyomi || "—")}</div></div>
            <div class="reading-card"><div class="rc-label">KUNYOMI</div><div class="rc-value">${esc(it.kunyomi || "—")}</div></div>
        </div>
        ${examples ? `<div class="detail-title">Contoh Kata &amp; Kalimat</div>${examples}` : ""}`;
}

function vocabDetail(it, level) {
    return `
        <div class="detail-hero">
            <div class="hero-badges"><span class="hero-badge">JLPT ${esc(level.id)}</span>
                <button class="speak-circle" style="background:rgba(255,255,255,.22);color:#fff" data-speak="${esc(it.kanji || it.hiragana)}" aria-label="Dengarkan">${icon("speaker")}</button></div>
            <div class="hero-glyph" style="font-size:clamp(48px,15vw,72px)">${esc(it.kanji)}</div>
            <div class="hero-romaji">${esc(it.hiragana)}</div>
            <div class="hero-sub">${esc(it.arti)}</div>
        </div>
        <div class="fact-grid">
            <div class="fact"><div class="fact-label">JENIS KATA</div><div class="fact-value accent">${esc(it.jenisKata || "—")}</div></div>
            <div class="fact"><div class="fact-label">LEVEL</div><div class="fact-value">${esc(it.level || level.id)}</div></div>
        </div>`;
}

function grammarDetail(it, level) {
    const softList = (arr, warn) => (arr || []).map((x) => warn
        ? `<div class="bullet-soft warn">${icon("xmark")}<span class="txt">${esc(x)}</span></div>`
        : `<div class="bullet-soft"><span class="dot"></span><span class="txt">${esc(x)}</span></div>`).join("");
    const examples = (it.examples || []).map((ex, i) => `
        <div class="example numbered">
            <span class="ex-num">${i + 1}</span>
            <div><div class="ex-sentence" style="margin-top:0">${esc(ex.japanese)}</div>
                <div class="ex-trans" style="color:var(--muted)">${esc(ex.romaji)}</div>
                <div style="font-size:14px;font-weight:700;margin-top:3px">${esc(ex.translation)}</div></div>
        </div>`).join("");

    return `
        <div class="detail-hero" style="text-align:left;padding:18px">
            <div class="hero-badges" style="align-items:center"><span class="hero-badge">JLPT ${esc(level.id)}</span>
                ${it.structure ? `<span class="hero-pill">${esc(it.structure)}</span>` : ""}</div>
            <div class="hero-romaji" style="font-size:30px;margin-top:8px">${esc(it.pattern)}</div>
            <div class="hero-sub">${esc(it.romaji)}</div>
            <div style="font-size:19px;font-weight:800;font-family:var(--font-display);margin-top:8px">${esc(it.meaning)}</div>
            <div class="hero-pills" style="justify-content:flex-start">
                <span class="hero-pill">${esc(level.id)}</span>
                ${it.treeCategory ? `<span class="hero-pill">${esc(it.treeCategory)}</span>` : ""}
                ${it.frequency ? `<span class="hero-pill">${esc(it.frequency)}</span>` : ""}
            </div>
        </div>
        ${(it.nuance || it.frequency) ? `<div class="fact-grid">
            <div class="fact"><div class="fact-label">NUANCE</div><div class="fact-value">${esc(it.nuance || "—")}</div></div>
            <div class="fact"><div class="fact-label">FREQUENCY</div><div class="fact-value accent">${esc(it.frequency || "—")}</div></div></div>` : ""}
        ${(it.explanation || it.meaning) ? sectionCard("Arti", "arti", `<div class="prose" style="font-size:14px;font-weight:600;color:var(--muted2);line-height:1.6">${esc(it.explanation || it.meaning)}</div>`) : ""}
        ${(it.usage && it.usage.length) ? sectionCard("Penggunaan", "usage", softList(it.usage, false)) : ""}
        ${(it.commonMistakes && it.commonMistakes.length) ? sectionCard("Kesalahan Umum", "warn", softList(it.commonMistakes, true), { warn: true }) : ""}
        ${examples ? sectionCard("Contoh Kalimat", "quotes", examples, { count: `${it.examples.length} kalimat` }) : ""}`;
}

// ---------- Hiragana / Katakana ----------

const isKatakana = (ch) => ch && ch.codePointAt(0) >= 0x30a0 && ch.codePointAt(0) <= 0x30ff;

export async function renderHiragana(app) {
    let groups;
    try { groups = await loadJSON("Hiragana"); }
    catch (e) { app.innerHTML = screenHeader("Huruf", route("home")) + `<div class="empty-state">${esc(e.message)}</div>`; return; }

    const firstKana = (g) => { for (const row of g.rows || []) for (const c of row) if (c && c.kana) return c.kana; return ""; };
    const hira = groups.filter((g) => !isKatakana(firstKana(g)));
    const kata = groups.filter((g) => isKatakana(firstKana(g)));
    const count = (gs) => gs.reduce((n, g) => n + (g.rows || []).reduce((m, r) => m + r.filter((c) => c && c.kana).length, 0), 0);

    const group = (g) => `
        <div class="kana-title">${esc(g.title || "")}</div>
        ${(g.rows || []).map((row) => `<div class="kana-grid">${row.map((c) => c && c.kana
            ? `<div class="kana-cell"><div class="k">${esc(c.kana)}</div><div class="r">${esc((c.romaji || "").toUpperCase())}</div></div>`
            : `<div class="kana-cell empty"></div>`).join("")}</div>`).join("")}`;

    const paint = (which) => {
        const gs = which === "kata" ? kata : hira;
        document.getElementById("kanaBox").innerHTML = gs.map(group).join("");
        document.getElementById("kpTotal").textContent = `0 dari ${count(gs)} huruf`;
    };

    app.innerHTML = screenHeader("Huruf", route("home")) + `
        <div class="seg-tabs">
            <button class="seg-tab active" id="tabHira">Hiragana</button>
            <button class="seg-tab" id="tabKata">Katakana</button>
        </div>
        <div class="kana-progress">
            <div class="kp-top"><span class="kp-t">Progres Hafalan</span><span class="kp-n" id="kpTotal"></span></div>
            <div class="kp-bar"><span style="width:3%"></span></div>
        </div>
        <div id="kanaBox"></div>`;

    const th = document.getElementById("tabHira"), tk = document.getElementById("tabKata");
    th.addEventListener("click", () => { th.classList.add("active"); tk.classList.remove("active"); paint("hira"); });
    tk.addEventListener("click", () => { tk.classList.add("active"); th.classList.remove("active"); paint("kata"); });
    paint("hira");
}

// ---------- Coming soon ----------

export function renderComingSoon(app, name) {
    app.innerHTML = screenHeader(name || "Lainnya", route("home")) +
        `<div class="empty-state">🔨<br><br><b>Segera Hadir</b><br>Fitur ini sedang dikembangkan.</div>`;
}
