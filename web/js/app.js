// Router + shell for the iOS-style layout: a fixed bottom tab bar (Home · Profil
// · Pengaturan) and hash-based navigation. The learning sections (kanji, vocab,
// grammar, hiragana, flashcard) are reached from the Home grid and shown as
// "pushed" screens with their own back button, so the Home tab stays selected.
// No build step — plain ES modules.

import { TABS } from "./levels.js";
import { renderHome, renderLevels, renderList, renderDetail, renderHiragana, renderComingSoon } from "./browse.js";
import { renderProfile } from "./profile.js";
import { initTheme } from "./theme.js";
import { icon } from "./icons.js";
import * as gsync from "./gsync.js";

const app = document.getElementById("app");
const tabbar = document.getElementById("tabbar");

// Which bottom tab owns a given route section.
const TAB_OF = { home: "home", kanji: "home", vocab: "home", grammar: "home",
    hiragana: "home", flashcard: "home", soon: "home",
    profile: "profile", settings: "settings" };

// ---------- Bottom tab bar ----------

function buildTabs() {
    tabbar.innerHTML = TABS.map(
        (t) => `<a class="tab-item" data-tab="${t.key}" href="#/${t.key}">
            ${icon(t.icon)}<span>${t.label}</span></a>`
    ).join("");
}
function setActiveTab(section) {
    const active = TAB_OF[section] || "home";
    tabbar.querySelectorAll(".tab-item").forEach((t) =>
        t.classList.toggle("active", t.dataset.tab === active)
    );
}

// ---------- Router ----------

function parseHash() {
    const raw = (location.hash || "#/home").replace(/^#\/?/, "");
    return raw.split("/").filter(Boolean); // e.g. ["kanji","N5","N5_001"]
}

async function router() {
    const [section = "home", level, id] = parseHash();
    setActiveTab(section);
    window.scrollTo(0, 0);
    // Retrigger the page-enter animation on every navigation.
    app.classList.remove("page-enter");
    void app.offsetWidth;
    app.classList.add("page-enter");

    try {
        switch (section) {
            case "home":
                return renderHome(app);
            case "profile":
                return renderProfile(app);
            case "kanji":
            case "vocab":
            case "grammar":
                if (id) return await renderDetail(app, section, level, id);
                if (level) return await renderList(app, section, level);
                return renderLevels(app, section);
            case "hiragana":
                return await renderHiragana(app);
            case "flashcard": {
                const mod = await import("./flashcards.js");
                return mod.renderFlashcard(app, level, id);
            }
            case "settings": {
                const mod = await import("./settings.js");
                return mod.renderSettings(app);
            }
            case "soon":
                return renderComingSoon(app, level);
            default:
                return renderHome(app);
        }
    } catch (err) {
        app.innerHTML = `<div class="empty-state">Terjadi kesalahan: ${err.message}</div>`;
    }
}

// ---------- Init ----------

initTheme();
buildTabs();
window.addEventListener("hashchange", router);
// After a Drive sync merges remote data, refresh the current view.
window.addEventListener("ichigo-synced", router);
// A finished study session triggers a background push (if auto-sync is on).
window.addEventListener("ichigo-session-done", () => gsync.autoSyncIfEnabled());
router();
// Pull-merge on load (silent — no-op unless configured, consented and enabled).
gsync.autoSyncIfEnabled();
