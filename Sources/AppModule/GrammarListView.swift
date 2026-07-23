import SwiftUI

// MARK: - Grammar List View
struct GrammarListView: View {
    let level: GrammarLevel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var items: [GrammarItem] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    
    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
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
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Memuat tata bahasa...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else if items.isEmpty {
                VStack(spacing: 12) {
                    Text("📂").font(.system(size: 48))
                    Text("File \(level.jsonFile).json belum ditambahkan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Cari tata bahasa...", text: $searchText)
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
                    .padding(.vertical, 10)
                    .background(bgColor)
                    
                    // List grammar
                    ScrollView {
                        VStack(spacing: 10) {
                            if filtered.isEmpty {
                                Text("Tidak ditemukan")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(bgColor)
                }
            }
        }
        .navigationTitle("Tata Bahasa \(level.id)")
        .navigationBarTitleDisplayMode(.large)
        .background(bgColor)
        .task {
            guard items.isEmpty else { return }
            let jsonFile = level.jsonFile
            let loaded = await Task.detached(priority: .userInitiated) {
                GrammarLoader.load(from: jsonFile)
            }.value
            items = loaded
            isLoading = false
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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    // Arti singkat
                    Text(item.meaning)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GrammarListView(level: grammarLevels[0])
    }
}
