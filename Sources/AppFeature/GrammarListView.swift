import SwiftUI

// MARK: - Grammar List View
struct GrammarListView: View {
    let level: GrammarLevel
    @Environment(\.colorScheme) var colorScheme

    @State private var items: [GrammarItem] = []
    @State private var searchText: String = ""
    @State private var loadState: ViewLoadState = .loading

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }

    var filtered: [GrammarItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return items }
        return items.filter {
            $0.pattern.contains(query) ||
            $0.meaning.localizedCaseInsensitiveContains(query) ||
            $0.explanation.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    var body: some View {
        Group {
            if loadState == .loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Memuat tata bahasa...")
                        .font(AppTheme.rounded(14))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else if case .failed(let message) = loadState {
                ErrorStateView(message: message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgColor)
            } else if loadState == .empty {
                EmptyStateView(title: "Coming soon", subtitle: "Konten level ini belum tersedia.", icon: "folder")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgColor)
            } else {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Tata Bahasa \(level.id)")

                    SearchField(placeholder: "Cari tata bahasa...", text: $searchText)
                        .padding(.horizontal, 20)

                    // List grammar. Lazy so a 160-pattern level only builds the
                    // rows that are on screen, matching the kanji and vocabulary
                    // lists.
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if filtered.isEmpty {
                                Text("Tidak ditemukan")
                                    .font(AppTheme.rounded(15))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                                    .padding(.top, 60)
                            } else {
                                ForEach(filtered) { item in
                                    NavigationLink(destination: GrammarDetailView(item: item)) {
                                        GrammarListCard(item: item, cardColor: cardColor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    .background(bgColor)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(bgColor)
        .task {
            guard items.isEmpty else { return }
            let jsonFile = level.jsonFile
            do {
                let loaded = try await Task.detached(priority: .userInitiated) {
                    try GrammarLoader.load(from: jsonFile)
                }.value
                items = loaded
                loadState = loaded.isEmpty ? .empty : .loaded
            } catch {
                loadState = .failed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Grammar List Card
struct GrammarListCard: View {
    let item: GrammarItem
    let cardColor: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Pola grammar
                    Text(item.pattern)
                        .font(AppTheme.rounded(20, .bold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                    // Arti singkat
                    Text(item.meaning)
                        .font(AppTheme.rounded(13))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AppTheme.rounded(12))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(14)
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GrammarListView(level: grammarLevels[0])
    }
}
