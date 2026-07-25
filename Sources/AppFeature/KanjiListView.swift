import SwiftUI

// MARK: - Kanji List View
struct KanjiListView: View {
    let level: JLPTLevel
    @Environment(\.colorScheme) var colorScheme


    @State private var kanjiItems: [KanjiItem] = []
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var loadState: ViewLoadState = .loading

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }

    var filtered: [KanjiItem] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return kanjiItems }
        return kanjiItems.filter { item in
            // Cari berdasarkan kanji langsung (日)
            item.kanji.contains(query) ||
            // Cari berdasarkan arti Indonesia (matahari, hari)
            item.meaning.localizedCaseInsensitiveContains(query) ||
            // Cari berdasarkan romaji (Nichi, Gaku)
            item.romaji.localizedCaseInsensitiveContains(query) ||
            // Cari berdasarkan onyomi (ニチ, ジツ)
            item.onyomi.localizedCaseInsensitiveContains(query) ||
            // Cari berdasarkan kunyomi (ひ, か)
            item.kunyomi.localizedCaseInsensitiveContains(query) ||
            // Cari berdasarkan kata contoh (学生, がくせい)
            item.examples.contains(where: {
                $0.word.contains(query) ||
                $0.reading.contains(query) ||
                $0.romaji.localizedCaseInsensitiveContains(query) ||
                $0.meaning.localizedCaseInsensitiveContains(query)
            })
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Group {
            if loadState == .loading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Memuat kanji \(level.id)...")
                        .font(AppTheme.rounded(14))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else if case .failed(let message) = loadState {
                ErrorStateView(message: message).frame(maxWidth: .infinity, maxHeight: .infinity).background(bgColor)
            } else if loadState == .empty {
                EmptyStateView(title: "Belum tersedia", subtitle: "Konten level ini belum tersedia.", icon: "folder").frame(maxWidth: .infinity, maxHeight: .infinity).background(bgColor)
            } else {
                VStack(spacing: 14) {
                    ScreenHeader(title: "JLPT \(level.id) Kanji")

                    SearchField(placeholder: "Cari Kanji (contoh: 日)", text: $searchText)
                        .padding(.horizontal, 20)

                    // Grid kanji
                    ScrollView {
                        if filtered.isEmpty {
                            VStack(spacing: 8) {
                                Text("Tidak ditemukan")
                                    .font(AppTheme.rounded(15))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filtered) { item in
                                    NavigationLink(destination: KanjiDetailView(item: item, levelId: level.id)) {
                                        KanjiCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                        }
                    }
                    .background(bgColor)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard kanjiItems.isEmpty else { return }
            let jsonFile = level.jsonFile
            do {
                let items = try await Task.detached(priority: .userInitiated) {
                    try KanjiLoader.load(from: jsonFile)
                }.value
                kanjiItems = items
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

// MARK: - Kanji Card (Grid Item)
struct KanjiCard: View {
    let item: KanjiItem
    @Environment(\.colorScheme) var colorScheme

    var cardColor: Color { AppTheme.surface(colorScheme) }

    var body: some View {
        VStack(spacing: 6) {
            // Kanji besar
            Text(item.kanji)
                .font(AppTheme.rounded(52, .light))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .frame(height: 65)

            // Onyomi / Kunyomi kecil
            Text("\(item.onyomi) / \(item.kunyomi)")
                .font(AppTheme.rounded(10))
                .foregroundColor(AppTheme.ocean)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 4)

            // Arti
            Text(item.meaning)
                .font(AppTheme.rounded(13, .semibold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(cardColor)
        .cornerRadius(14)
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

}

// MARK: - Preview
#Preview {
    NavigationView {
        KanjiListView(level: jlptLevels[0])
    }
}
