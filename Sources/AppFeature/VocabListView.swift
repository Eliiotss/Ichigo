import SwiftUI

// MARK: - Daftar Kosakata

/// Daftar seluruh kosakata pada satu level JLPT, lengkap dengan pencarian dan
/// penyaring jenis kata.
struct VocabularyListView: View {
    let level: VocabularyLevel
    @Environment(\.colorScheme) var colorScheme

    @State private var words: [VocabularyItem] = []
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var loadState: ViewLoadState = .loading
    @State private var selectedFilter: String = "Semua"

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }

    var availableFilters: [String] {
        var seen = Set<String>()
        var ordered: [String] = ["Semua"]
        for word in words where seen.insert(word.jenisKata).inserted {
            ordered.append(word.jenisKata)
        }
        return ordered
    }

    var filtered: [VocabularyItem] {
        let q = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = words

        if selectedFilter != "Semua" {
            result = result.filter { $0.jenisKata == selectedFilter }
        }

        guard !q.isEmpty else { return result }
        return result.filter {
            $0.kanji.contains(q) ||
            $0.hiragana.contains(q) ||
            $0.arti.localizedCaseInsensitiveContains(q) ||
            $0.jenisKata.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        Group {
            if loadState == .loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Memuat kosakata \(level.id)...")
                        .font(AppTheme.rounded(14))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if case .failed(let message) = loadState {
                ErrorStateView(message: message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadState == .empty {
                EmptyStateView(title: "Belum tersedia", subtitle: "Konten level ini belum tersedia.", icon: "folder")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Header, pencarian, dan penyaring tetap diam; hanya daftarnya
                // yang menggulir.
                VStack(spacing: 14) {
                    ScreenHeader(title: "JLPT \(level.id) Vocabulary")

                    SearchField(placeholder: "Cari kosakata", text: $searchText)
                        .padding(.horizontal, 20)

                    FilterChipRow(filters: availableFilters, selection: $selectedFilter)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if filtered.isEmpty {
                                Text("Tidak ditemukan")
                                    .font(AppTheme.rounded(15, .medium))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                                    .padding(.top, 60)
                            } else {
                                ForEach(filtered) { item in
                                    VocabularyInlineCard(item: item, levelId: level.id, cardColor: cardColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 4)
            }
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard words.isEmpty else { return }
            let jsonFile = level.jsonFile
            do {
                let items = try await Task.detached(priority: .userInitiated) {
                    try VocabularyLoader.load(from: jsonFile)
                }.value
                words = items
                loadState = items.isEmpty ? .empty : .loaded
            } catch {
                loadState = .failed(error.localizedDescription)
            }
        }
        .onChange(of: searchText) { _, newValue in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000)
                if searchText == newValue {
                    debouncedSearchText = newValue
                }
            }
        }
    }
}

// MARK: - Kartu Kosakata

/// Kartu satu kosakata. Seluruh detailnya tampil langsung di daftar sehingga
/// pengguna tidak perlu membuka halaman lain: lencana level dan tombol suara di
/// baris atas, lalu kanji, cara baca, jenis kata, dan artinya.
struct VocabularyInlineCard: View {
    let item: VocabularyItem
    let levelId: String
    let cardColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("JLPT \(levelId)")
                    .font(AppTheme.rounded(11, .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())

                Spacer()

                Button(action: { AudioSpeechHelper.shared.speak(item.kanji) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(AppTheme.rounded(15, .semibold))
                        .foregroundColor(AppTheme.accent)
                        .padding(10)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dengarkan pelafalan \(item.kanji)")
            }

            Text(item.kanji)
                .font(AppTheme.rounded(34, .bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(item.hiragana)
                .font(AppTheme.rounded(14, .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))

            Text(item.jenisKata)
                .font(AppTheme.rounded(13, .bold))
                .foregroundColor(AppTheme.accent)

            Text(item.arti)
                .font(AppTheme.rounded(17, .medium))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
}
