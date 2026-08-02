// localStorage persistence for flashcard progress, the daily new-card quota, and
// the study streak. Keys are namespaced under `ichigo_`.

const K = {
    progress: "ichigo_progress_v1",
    settings: "ichigo_settings_v1",
    newToday: "ichigo_new_today_v1",
    streak: "ichigo_streak_v1",
};

function read(key, fallback) {
    try {
        const raw = localStorage.getItem(key);
        return raw ? JSON.parse(raw) : fallback;
    } catch {
        return fallback;
    }
}
function write(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* quota / private mode */ }
}

function dayKey(d = new Date()) {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

// ---------- Progress ----------

export function allProgress() { return read(K.progress, {}); }
export function getProgress(id) { return allProgress()[id] || null; }
export function saveProgress(p) {
    const all = allProgress();
    all[p.id] = p;
    write(K.progress, all);
}

// ---------- Settings ----------

export function getDailyTarget() { return read(K.settings, {}).dailyTarget ?? 20; }
export function setDailyTarget(n) {
    const s = read(K.settings, {});
    s.dailyTarget = Math.max(1, n | 0);
    write(K.settings, s);
}

// ---------- Daily new-card quota ----------

/// How many brand-new cards have been introduced today for a given deck.
export function newTodayCount(deckKey) {
    const store = read(K.newToday, {});
    const today = dayKey();
    if (store.day !== today) return 0;
    return (store.counts && store.counts[deckKey]) || 0;
}
export function incrementNewToday(deckKey, by = 1) {
    const today = dayKey();
    let store = read(K.newToday, {});
    if (store.day !== today) store = { day: today, counts: {} };
    store.counts[deckKey] = (store.counts[deckKey] || 0) + by;
    write(K.newToday, store);
}

// ---------- Streak ----------

export function getStreak() { return read(K.streak, { count: 0, lastDay: null }); }

/// Marks today as studied and updates the streak (consecutive-day count).
export function recordStudyToday() {
    const s = getStreak();
    const today = dayKey();
    if (s.lastDay === today) return s.count;
    const yesterday = dayKey(new Date(Date.now() - 86_400_000));
    s.count = s.lastDay === yesterday ? s.count + 1 : 1;
    s.lastDay = today;
    write(K.streak, s);
    return s.count;
}

// ---------- Username ----------

export function getUsername() { return read(K.settings, {}).username || ""; }
export function setUsername(name) {
    const s = read(K.settings, {});
    s.username = String(name || "").slice(0, 40);
    write(K.settings, s);
}

// ---------- Export / Import (backup with Anki-style merge) ----------

/// A portable snapshot of all local learning state.
export function exportState() {
    return {
        app: "ichigo-web",
        version: 1,
        exportedAt: Date.now(),
        progress: allProgress(),
        settings: read(K.settings, {}),
        newToday: read(K.newToday, {}),
        streak: getStreak(),
    };
}

/// Merges two progress maps: per card, the copy with the newer `lastReview`
/// wins (ties break toward more reps). Mirrors the iOS `BackupMerge` rule so no
/// review progress is lost across devices/browsers.
export function mergeProgressMaps(localMap, remoteMap) {
    const merged = { ...localMap };
    for (const [id, r] of Object.entries(remoteMap || {})) {
        const l = merged[id];
        if (!l) { merged[id] = r; continue; }
        const lr = l.lastReview || 0, rr = r.lastReview || 0;
        if (rr > lr || (rr === lr && (r.reps || 0) > (l.reps || 0))) merged[id] = r;
    }
    return merged;
}

/// Imports a snapshot, merging it into the current state (never destructive):
/// progress by newest review, streak by max, settings/username by newer export.
export function importState(incoming) {
    if (!incoming || incoming.app !== "ichigo-web") throw new Error("Berkas cadangan tidak dikenali.");
    // Progress: merge per card.
    write(K.progress, mergeProgressMaps(allProgress(), incoming.progress));
    // Settings: newer export wins per field, keep existing when absent.
    const localS = read(K.settings, {});
    write(K.settings, { ...localS, ...(incoming.settings || {}) });
    // Streak: keep the larger count.
    const localStreak = getStreak();
    const inStreak = incoming.streak || { count: 0, lastDay: null };
    write(K.streak, inStreak.count > localStreak.count ? inStreak : localStreak);
    // New-today: keep same-day max so today's quota isn't double-spent or reset.
    const localNT = read(K.newToday, {});
    const inNT = incoming.newToday || {};
    if (inNT.day && inNT.day === localNT.day) {
        const counts = { ...(localNT.counts || {}) };
        for (const [k, v] of Object.entries(inNT.counts || {})) counts[k] = Math.max(counts[k] || 0, v);
        write(K.newToday, { day: localNT.day, counts });
    } else if (inNT.day && !localNT.day) {
        write(K.newToday, inNT);
    }
    return { progress: Object.keys(allProgress()).length };
}

// ---------- Reset ----------

export function resetAll() {
    Object.values(K).forEach((k) => localStorage.removeItem(k));
}
