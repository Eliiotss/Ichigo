import SwiftUI

// MARK: - Daftar Pola Tata Bahasa

/// Daftar seluruh pola tata bahasa pada satu level JLPT.
struct GrammarListView: View {
    let level: GrammarLevel
    @Environment(\.colorScheme) var colorScheme

    @State private var items: [GrammarItem] = []
    @State private var loadState: ViewLoadState = .loading

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }

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
                EmptyStateView(title: "Belum tersedia", subtitle: "Konten level ini belum tersedia.", icon: "folder")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgColor)
            } else {
                // Header tetap di tempatnya, hanya daftarnya yang menggulir.
                VStack(spacing: 14) {
                    ScreenHeader(title: "Grammar")

                    // Daftar pola. Pakai LazyVStack supaya level dengan 160 pola
                    // hanya membangun baris yang terlihat di layar.
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink(destination: GrammarDetailView(item: item)) {
                                    GrammarListCard(item: item, levelId: level.id, cardColor: cardColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
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

// MARK: - Kartu Pola Tata Bahasa

/// Kartu satu pola tata bahasa di daftar.
///
/// Susunannya mengikuti desain: lencana level di kiri atas dengan kategori pola
/// di kanannya, lalu pola berukuran besar, romaji abu-abu, dan artinya dengan
/// warna aksen biar langsung kelihatan saat menggulir daftar.
struct GrammarListCard: View {
    let item: GrammarItem
    let levelId: String
    let cardColor: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text("JLPT \(levelId)")
                    .font(AppTheme.rounded(11, .bold))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Capsule())

                Spacer(minLength: 0)

                // Kategori pola, mis. "Kalimat Dasar" atau "Predikat".
                if !item.treeCategory.isEmpty {
                    Text(item.treeCategory)
                        .font(AppTheme.rounded(12, .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Text(item.pattern)
                .font(AppTheme.rounded(26, .bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            if !item.romaji.isEmpty {
                Text(item.romaji)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .padding(.top, 3)
            }

            Text(item.meaning)
                .font(AppTheme.rounded(15, .bold))
                .foregroundColor(AppTheme.accent)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GrammarListView(level: grammarLevels[0])
    }
}
