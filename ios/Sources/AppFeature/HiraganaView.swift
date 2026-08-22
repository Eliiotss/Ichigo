import SwiftUI

// MARK: - Kana Data
struct KanaItem: Identifiable, Hashable {
    let id = UUID()
    let kana: String
    let romaji: String
}

struct KanaGroup: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let items: [[KanaItem?]]
    let columns: [String]
}

// MARK: - JSON Codable Model (untuk load dari file)
struct KanaItemJSON: Codable {
    let kana: String
    let romaji: String
}

struct KanaGroupJSON: Codable {
    let title: String
    let subtitle: String
    let columns: [String]
    let rows: [[KanaItemJSON?]]
}

// MARK: - Kana Loader
enum KanaLoader {
    static func load(from filename: String) -> [KanaGroup] {
        ResourceLoader.loadArrayOrEmpty(KanaGroupJSON.self, from: filename).map { group in
            KanaGroup(
                title: group.title,
                subtitle: group.subtitle,
                items: group.rows.map { row in row.map { item in item.map { KanaItem(kana: $0.kana, romaji: $0.romaji) } } },
                columns: group.columns
            )
        }
    }

    static func flatItems(from groups: [KanaGroup]) -> [KanaItem] {
        groups.flatMap { $0.items.flatMap { $0.compactMap { $0 } } }
    }
}

extension KanaGroup {
    /// Classifies a group by the Unicode block of its characters. The kana
    /// dataset ships hiragana and katakana in a single file, so this is used to
    /// route each group to the correct tab.
    var isKatakanaScript: Bool {
        for row in items {
            for case let item? in row {
                guard let value = item.kana.unicodeScalars.first?.value else { continue }
                if value >= 0x30A0 && value <= 0x30FF { return true }  // Katakana block
                if value >= 0x3040 && value <= 0x309F { return false } // Hiragana block
            }
        }
        return false
    }
}

// MARK: - Main View
struct HiraganaView: View {
    @StateObject private var store = HiraganaStore()
    @State private var selectedTab: Int = 0
    @State private var showFlashcard = false
    @State private var hiraganaGroups: [KanaGroup] = []
    @State private var katakanaGroups: [KanaGroup] = []
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme

    var isKatakana: Bool { selectedTab == 1 }
    var currentGroups: [KanaGroup] { isKatakana ? katakanaGroups : hiraganaGroups }
    var currentFlat: [KanaItem] { KanaLoader.flatItems(from: currentGroups) }

    var mainGroups: [KanaGroup] {
        currentGroups.filter { group in
            !group.title.localizedCaseInsensitiveContains("Yōon") &&
            !group.title.localizedCaseInsensitiveContains("Gabungan")
        }
    }

    var mainFlat: [KanaItem] {
        KanaLoader.flatItems(from: mainGroups)
    }

    var yoonUnlockThreshold: Int {
        Int((Double(mainFlat.count) * 0.5).rounded(.up))
    }

    var masteredMainCount: Int {
        store.masteredCount(flat: mainFlat, isKatakana: isKatakana)
    }

    var isYoonUnlocked: Bool {
        masteredMainCount >= yoonUnlockThreshold
    }

    var flashcardFlat: [KanaItem] {
        isYoonUnlocked ? currentFlat : mainFlat
    }

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var cardColor: Color { AppTheme.surface(colorScheme) }

    var masteredCount: Int {
        store.masteredCount(flat: currentFlat, isKatakana: isKatakana)
    }

    var progressValue: Double {
        store.progressPercent(flat: currentFlat, isKatakana: isKatakana)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Hiragana").tag(0)
                    Text("Katakana").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bgColor)

                if isLoading {
                    Spacer()
                    ProgressView("Memuat huruf...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Kartu ringkasan progres: judul di kiri, hitungan di
                            // kanan, lalu bilah kemajuannya.
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Progres Hafalan")
                                        .font(AppTheme.rounded(16, .bold))
                                        .foregroundStyle(AppTheme.primaryText(colorScheme))

                                    Spacer()

                                    Text("\(masteredCount) dari \(currentFlat.count) huruf")
                                        .font(AppTheme.rounded(13))
                                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(AppTheme.trackColor(colorScheme))
                                            .frame(height: 8)

                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: isKatakana
                                                    ? [AppTheme.indigo, AppTheme.navy]
                                                    : [AppTheme.blueLight, AppTheme.blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(8, geo.size.width * CGFloat(progressValue)), height: 8)
                                            .animation(.easeInOut(duration: 0.5), value: progressValue)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(16)
                            .background(AppTheme.surface(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                            .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            ForEach(currentGroups) { group in
                                KanaGroupSection(
                                    group: group,
                                    store: store,
                                    isKatakana: isKatakana,
                                    cardColor: cardColor
                                )
                            }

                            Spacer().frame(height: 90)
                        }
                    }
                    .background(bgColor)
                }
            }

            if !isLoading {
                Button(action: { showFlashcard = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(AppTheme.rounded(16, .bold))

                        Text("Flashcard \(isKatakana ? "Katakana" : "Hiragana")")
                            .font(AppTheme.rounded(16, .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isKatakana ? AppTheme.indigo : AppTheme.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: (isKatakana ? AppTheme.indigo : AppTheme.blue).opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Huruf")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showFlashcard) {
            HiraganaFlashcardView(
                store: store,
                isKatakana: isKatakana,
                deckFlat: flashcardFlat,
                progressFlat: currentFlat
            )
        }
        .task {
            guard hiraganaGroups.isEmpty && katakanaGroups.isEmpty else { return }

            // Hiragana.json contains both scripts; split it into the two tabs
            // by character block instead of loading a separate Katakana file.
            let allGroups = await Task.detached(priority: .userInitiated) {
                KanaLoader.load(from: "Hiragana")
            }.value

            await MainActor.run {
                hiraganaGroups = allGroups.filter { !$0.isKatakanaScript }
                katakanaGroups = allGroups.filter { $0.isKatakanaScript }
                isLoading = false
            }
        }
    }
}

// MARK: - Kana Group Section
struct KanaGroupSection: View {
    let group: KanaGroup
    let store: HiraganaStore
    let isKatakana: Bool
    let cardColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(AppTheme.rounded(18, .bold))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))
                    .padding(.horizontal, 16)

                if !group.subtitle.isEmpty {
                    Text(group.subtitle)
                        .font(AppTheme.rounded(13))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        .padding(.horizontal, 16)
                }
            }

            HStack(spacing: 0) {
                ForEach(group.columns, id: \.self) { col in
                    Text(col.uppercased())
                        .font(AppTheme.rounded(10, .bold))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 4) {
                ForEach(0..<group.items.count, id: \.self) { rowIdx in
                    HStack(spacing: 4) {
                        ForEach(0..<group.items[rowIdx].count, id: \.self) { colIdx in
                            if let item = group.items[rowIdx][colIdx] {
                                KanaCellView(
                                    item: item,
                                    barProgress: store.barProgress(item.kana, isKatakana: isKatakana),
                                    isMastered: store.isMastered(item.kana, isKatakana: isKatakana),
                                    isKatakana: isKatakana,
                                    cardColor: cardColor
                                )
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 68)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

// MARK: - Kana Cell View
struct KanaCellView: View {
    let item: KanaItem
    let barProgress: Double
    let isMastered: Bool
    let isKatakana: Bool
    let cardColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var accentColor: Color {
        isKatakana ? AppTheme.indigo : AppTheme.blue
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(item.kana)
                .font(AppTheme.rounded(26, .semibold))
                .foregroundStyle(AppTheme.primaryText(colorScheme))

            Text(item.romaji.uppercased())
                .font(AppTheme.rounded(9, .bold))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .kerning(0.5)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.trackColor(colorScheme))
                        .frame(height: 3)

                    Capsule()
                        .fill(isMastered ? AppTheme.success : accentColor)
                        .frame(width: geo.size.width * CGFloat(barProgress), height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 10)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isMastered ? AppTheme.success.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        HiraganaView()
    }
}
