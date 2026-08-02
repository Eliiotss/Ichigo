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

// ---------- Reset ----------

export function resetAll() {
    Object.values(K).forEach((k) => localStorage.removeItem(k));
}
