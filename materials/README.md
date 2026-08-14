# materials/

Materi belajar pribadi — **terpisah dari kode aplikasi IchiGo**. Bukan bagian
dari dataset app; tidak dipakai saat build.

- `materi.md` — kosakata: tabel `| Kata | Bacaan | Arti | Contoh |`.
  **11.684 kata unik** (dedup kata+bacaan). Furigana pada Contoh dipertahankan.
- `grammar.md` — tata bahasa: tabel `| Level | Pola | Penjelasan | Contoh | Arti |`.
  **809 pola** (N5=104, N4=169, N3=215, N2=210, N1=111), diurutkan per level.
- `tidy_materi.py` / `tidy_grammar.py` — skrip pembuatnya. Perbarui dengan:
  `python3 tidy_materi.py "ekspor-anki.txt" materi.md`
  `python3 tidy_grammar.py "ekspor-anki.txt" grammar.md`

Keduanya diambil **materi/kontennya saja** dari ekspor Anki (data teknis
guid/HTML/audio/sumber dibuang). Disimpan untuk keperluan belajar pribadi.
