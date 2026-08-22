// Async dataset loader with an in-memory cache. Datasets live in web/data/ as
// copies of the app's JSON resources, so the site is self-contained and can be
// served statically (GitHub Pages, `python3 -m http.server`, etc.).

const cache = new Map();
const inflight = new Map();

export async function loadJSON(name) {
    if (cache.has(name)) return cache.get(name);
    if (inflight.has(name)) return inflight.get(name);

    const promise = fetch(`data/${name}.json`)
        .then((res) => {
            if (!res.ok) throw new Error(`Gagal memuat ${name} (${res.status})`);
            return res.json();
        })
        .then((data) => {
            cache.set(name, data);
            inflight.delete(name);
            return data;
        })
        .catch((err) => {
            inflight.delete(name);
            throw err;
        });

    inflight.set(name, promise);
    return promise;
}

/// Loads every unlocked dataset for a section keyed by level id, e.g.
/// `{ N5: [...], N4: [...], N3: [...] }`. Used by the flashcard deck builder.
export async function loadSection(levels) {
    const open = levels.filter((l) => !l.locked);
    const results = await Promise.all(open.map((l) => loadJSON(l.file)));
    const byLevel = {};
    open.forEach((l, i) => { byLevel[l.id] = results[i]; });
    return byLevel;
}
