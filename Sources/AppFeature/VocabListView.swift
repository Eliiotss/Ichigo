
import SwiftUI

struct VocabularyListView: View {
    let level: VocabularyLevel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var words: [VocabularyItem] = []
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var loadState: ViewLoadState = .loading
    @State private var selectedFilter: String = "Semua"
    
    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
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
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Cari kosakata", text: $searchText)
                            .font(.system(size: 15))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(cardColor)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Filter tab jenis kata
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableFilters, id: \.self) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text(filter)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? AppTheme.accent : cardColor)
                                        .cornerRadius(20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    // List kartu detail langsung (tanpa klik masuk halaman baru)
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if filtered.isEmpty {
                                Text("Tidak ditemukan")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 60)
                            } else {
                                ForEach(filtered) { item in
                                    VocabularyInlineCard(item: item, levelId: level.id, cardColor: cardColor)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .background(bgColor)
        .navigationTitle("JLPT \(level.id) Vocabulary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard words.isEmpty else { return }
            let jsonFile = level.jsonFile
            let items = await Task.detached(priority: .userInitiated) {
                VocabularyLoader.load(from: jsonFile)
            }.value
            words = items
            loadState = items.isEmpty ? .empty : .loaded
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
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent)
                    .cornerRadius(6)
                Spacer()
                Button(action: { AudioSpeechHelper.shared.speak(item.kanji) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                        .padding(8)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text(item.kanji)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text(item.hiragana)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Text(item.jenisKata)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.ocean)
            
            Text(item.arti)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .cornerRadius(16)
    }
}
