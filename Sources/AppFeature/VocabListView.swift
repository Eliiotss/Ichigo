
import SwiftUI

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
                ProgressView("Memuat vocabulary \(level.id)...")
            } else if case .failed(let message) = loadState {
                ErrorStateView(message: message)
            } else if loadState == .empty {
                EmptyStateView(title: "Coming soon", subtitle: "Konten level ini belum tersedia.", icon: "folder")
            } else {
                // Header, search and filters stay pinned; only the list scrolls.
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

// MARK: - Kartu Vocab Inline (detail lengkap tanpa klik)
struct VocabularyInlineCard: View {
    let item: VocabularyItem
    let levelId: String
    let cardColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("JLPT \(levelId)")
                    .font(AppTheme.rounded(10, .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent)
                    .cornerRadius(6)
                Spacer()
                Button(action: { AudioSpeechHelper.shared.speak(item.kanji) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(AppTheme.rounded(15, .semibold))
                        .foregroundColor(AppTheme.accent)
                        .padding(8)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text(item.kanji)
                .font(AppTheme.rounded(32, .bold))
                .foregroundColor(.primary)

            Text(item.hiragana)
                .font(AppTheme.rounded(15, .medium))
                .foregroundColor(.secondary)

            Text(item.jenisKata)
                .font(AppTheme.rounded(13, .bold))
                .foregroundColor(AppTheme.ocean)

            Text(item.arti)
                .font(AppTheme.rounded(16, .medium))
                .foregroundColor(.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
