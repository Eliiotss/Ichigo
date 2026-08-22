// Router + responsive chrome for the iOS-style design: a collapsible desktop
// sidebar (full nav), a mobile bottom tab bar (Home · Profil · Pengaturan), and a
// shared top bar (menu toggle + contextual back button/title). Screen renderers
// fill #content only. Hash-based routing, no build step.

import { renderHome, renderLevels, renderList, renderDetail, renderHiragana, renderComingSoon } from "./browse.js";
import { renderProfile } from "./profile.js";
import { checkReminder } from "./reminder.js";
import * as store from "./store.js";
import * as gsync from "./gsync.js";

const content = document.getElementById("content");
const sideNav = document.getElementById("sideNav");
const sideTarget = document.getElementById("sideTarget");
const tabbar = document.getElementById("tabbar");
const topbar = document.getElementById("topbar");
const shell = document.getElementById("shell");

// nav key -> route section; the reverse map drives active highlighting.
const NAV = [
    { key: "home", label: "Home", icon: "⌂", route: "home" },
    { key: "huruf", label: "Huruf", icon: "あ", route: "hiragana" },
    { key: "kanji", label: "Kanji", icon: "漢", route: "kanji" },
    { key: "flashcard", label: "Flashcard", icon: "札", route: "flashcard" },
    { key: "vocabulary", label: "Vocabulary", icon: "語", route: "vocab" },
    { key: "grammar", label: "Grammar", icon: "文", route: "grammar" },
    { key: "profil", label: "Profil", icon: "◍", route: "profile" },
    { key: "pengaturan", label: "Pengaturan", icon: "⚙", route: "settings" },
];
const TABS = [
    { label: "Home", icon: "⌂", route: "home" },
    { label: "Profil", icon: "◍", route: "profile" },
    { label: "Pengaturan", icon: "⚙", route: "settings" },
];
const NAV_OF = { home: "home", hiragana: "huruf", kanji: "kanji", vocab: "vocabulary",
    grammar: "grammar", flashcard: "flashcard", profile: "profil", settings: "pengaturan", soon: "home" };
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

// ---------- Chrome ----------

function buildChrome() {
    sideNav.innerHTML = NAV.map((n) =>
        `<a class="side-item" data-nav="${n.route}" href="#/${n.route}" title="${n.label}"><span class="ic">${n.icon}</span><span class="lbl">${n.label}</span></a>`).join("");
    tabbar.innerHTML = TABS.map((t) =>
        `<a class="tab-item" data-nav="${t.route}" href="#/${t.route}"><span class="ic">${t.icon}</span>${t.label}</a>`).join("");
    if (localStorage.getItem("ichigo_side_collapsed") === "1") shell.classList.add("collapsed");
}

function refreshSide() {
    const studied = store.studiedTodayTotal();
    const target = store.getDailyTarget();
    sideTarget.innerHTML = `<div class="lab">TARGET HARIAN</div><div class="num"><b>${studied}</b><span>/ ${target} kartu</span></div>`;
}

const PARENT = { hiragana: "Huruf", kanji: "Kanji", vocab: "Vocabulary", grammar: "Grammar", flashcard: "Flashcard" };
function titleFor(parts) {
    const [section, level, id] = parts;
    if (section === "profile") return "Profile";
    if (section === "settings") return "Pengaturan";
    if (section === "hiragana") return "Huruf";
    if (section === "soon") return "Lainnya";
    if (section === "flashcard") return id ? "Sesi Flashcard" : level ? "Flashcard " + cap(level) : "Flashcard";
    if (["kanji", "vocab", "grammar"].includes(section)) {
        const name = PARENT[section];
        if (id) return "Detail " + (section === "kanji" ? "Kanji" : section === "vocab" ? "Kosakata" : "Grammar");
        if (level) return section === "grammar" ? `Tata Bahasa ${level}` : `JLPT ${level} ${name}`;
        return name;
    }
    return "";
}
const cap = (s) => s ? s[0].toUpperCase() + s.slice(1) : s;

function renderTopbar(parts) {
    const isHome = parts[0] === "home" || !parts[0];
    const toggle = `<button class="menu-toggle" id="sideToggle" type="button" aria-label="Menu">☰</button>`;
    const back = isHome ? "" :
        `<div class="back-row"><a class="back-btn" href="${parentHash(parts)}">‹ Kembali</a><span class="page-title">${esc(titleFor(parts))}</span></div>`;
    topbar.innerHTML = (isHome ? toggle : toggle + back);
    const t = document.getElementById("sideToggle");
    if (t) t.addEventListener("click", () => {
        shell.classList.toggle("collapsed");
        localStorage.setItem("ichigo_side_collapsed", shell.classList.contains("collapsed") ? "1" : "0");
    });
}
function parentHash(parts) {
    return parts.length <= 1 ? "#/home" : "#/" + parts.slice(0, -1).join("/");
}

function setActive(section) {
    const key = NAV_OF[section] || "home";
    // NAV_OF maps section->nav key, but data-nav stores the route; map back.
    const activeRoute = (NAV.find((n) => n.key === key) || {}).route;
    document.querySelectorAll("[data-nav]").forEach((el) =>
        el.classList.toggle("active", el.dataset.nav === activeRoute));
}

// ---------- Router ----------

function parseHash() {
    return (location.hash || "#/home").replace(/^#\/?/, "").split("/").filter(Boolean);
}

async function router() {
    const parts = parseHash();
    const [section = "home", level, id] = parts;
    setActive(section);
    refreshSide();
    renderTopbar(parts);
    window.scrollTo(0, 0);
    content.classList.remove("page-enter"); void content.offsetWidth; content.classList.add("page-enter");
    try {
        switch (section) {
            case "home": return renderHome(content);
            case "profile": return renderProfile(content);
            case "kanji":
            case "vocab":
            case "grammar":
                if (id) return await renderDetail(content, section, level, id);
                if (level) return await renderList(content, section, level);
                return renderLevels(content, section);
            case "hiragana": return await renderHiragana(content);
            case "flashcard": { const m = await import("./flashcards.js"); return m.renderFlashcard(content, level, id); }
            case "settings": { const m = await import("./settings.js"); return m.renderSettings(content); }
            case "soon": return renderComingSoon(content, level);
            default: return renderHome(content);
        }
    } catch (err) {
        content.innerHTML = `<div class="empty">Terjadi kesalahan: ${esc(err.message)}</div>`;
    }
}

// ---------- Init ----------

buildChrome();
window.addEventListener("hashchange", router);
window.addEventListener("ichigo-synced", router);
window.addEventListener("ichigo-session-done", () => gsync.autoSyncIfEnabled());
router();
gsync.autoSyncIfEnabled();
checkReminder();
document.addEventListener("visibilitychange", () => { if (!document.hidden) checkReminder(); });
