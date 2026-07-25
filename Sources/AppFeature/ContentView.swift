import SwiftUI

// MARK: - MenuItem
struct MenuItem {
    let id: String
    let label: String
    let sub: String
    let icon: String
    let gradientColors: [Color]
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var flashcardStore = FlashcardStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, flashcardStore: flashcardStore)
                .tabItem { Image(systemName: "house.fill"); Text("Home") }
                .tag(0)

            ProfileView(flashcardStore: flashcardStore)
                .tabItem { Image(systemName: "person.fill"); Text("Profile") }
                .tag(1)

            SettingsView()
                .tabItem { Image(systemName: "gearshape.fill"); Text("Pengaturan") }
                .tag(2)
        }
        .accentColor(AppTheme.accent)
        .task { await preloadHomeStats() }
    }

    private func preloadHomeStats() async {
        for mode in FlashcardMode.allCases {
            for level in mode.levels() where !level.isLocked {
                await flashcardStore.loadDeck(mode: mode, levelId: level.id, jsonFile: level.jsonFile)
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Binding var selectedTab: Int
    @ObservedObject var flashcardStore: FlashcardStore
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject private var account = AccountStore.shared
    @AppStorage("daily_target") private var dailyTarget = 20

    let menuItems: [MenuItem] = [
        MenuItem(id: "huruf", label: "Huruf", sub: "Kana", icon: "character", gradientColors: AppTheme.tileGradient("huruf")),
        MenuItem(id: "kanji", label: "Kanji", sub: "Aksara", icon: "character.book.closed", gradientColors: AppTheme.tileGradient("kanji")),
        MenuItem(id: "flashcard", label: "Flashcard", sub: "Review Cepat", icon: "rectangle.stack.fill", gradientColors: AppTheme.tileGradient("flashcard")),
        MenuItem(id: "vocabulary", label: "Vocabulary", sub: "Kosakata", icon: "book.fill", gradientColors: AppTheme.tileGradient("vocabulary")),
        MenuItem(id: "grammar", label: "Grammar", sub: "Tata Bahasa", icon: "text.book.closed.fill", gradientColors: AppTheme.tileGradient("grammar")),
        MenuItem(id: "lainnya", label: "Lainnya", sub: "Fitur Lain", icon: "square.grid.2x2.fill", gradientColors: AppTheme.tileGradient("lainnya"))
    ]

    var dueTodayTotal: Int { flashcardStore.dueTodayGrandTotal }

    var body: some View {
        GeometryReader { geo in
            let isIPad = geo.size.width > 600
            let columns = isIPad
                ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                : [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        greetingHeader
                            .padding(.bottom, 16)

                        heroCard
                            .padding(.bottom, 18)

                        Text("BELAJAR MANDIRI")
                            .font(AppTheme.rounded(12, .heavy))
                            .kerning(1.2)
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .padding(.horizontal, 2)
                            .padding(.bottom, 10)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(menuItems, id: \.id) { item in
                                menuDestination(for: item, isIPad: isIPad)
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? 32 : 18)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .background(AppTheme.screenBackground(colorScheme).ignoresSafeArea())
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Okaeri 🍓")
                    .font(AppTheme.rounded(13, .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                Text("Halo, \(account.displayName)")
                    .font(AppTheme.rounded(26, .heavy))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 12)

            Button {
                selectedTab = 1
            } label: {
                Text(account.initials)
                    .font(AppTheme.rounded(17, .heavy))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.accentGradient)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.blue.opacity(0.35), radius: 8, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buka profil")
        }
    }

    // MARK: - Hero progress card

    private var heroCard: some View {
        let progress = dailyTarget > 0
            ? min(Double(flashcardStore.studiedTodayTotal) / Double(dailyTarget), 1)
            : 0

        return VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("PROGRESS HARI INI")
                    .font(AppTheme.rounded(13, .heavy))
                    .kerning(0.4)
                    .opacity(0.9)
                Spacer()
                Text("\(flashcardStore.studiedTodayTotal)/\(dailyTarget)")
                    .font(AppTheme.rounded(15, .heavy))
            }

            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.28))
                    Capsule().fill(Color.white)
                        .frame(width: max(bar.size.width * progress, progress > 0 ? 8 : 0))
                }
            }
            .frame(height: 9)

            HStack(spacing: 10) {
                heroStat(value: "\(dueTodayTotal)", label: "Due", showDivider: false)
                heroStat(value: "🔥 \(flashcardStore.currentStreak)", label: "Streak", showDivider: true)
                heroStat(value: "\(flashcardStore.masteredTotal)", label: "Mastered", showDivider: true)
            }
        }
        .padding(20)
        .foregroundColor(.white)
        .background(
            ZStack(alignment: .topTrailing) {
                AppTheme.accentGradient
                Circle().fill(Color.white.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .offset(x: 24, y: -24)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
        .shadow(color: AppTheme.blue.opacity(0.35), radius: 16, x: 0, y: 14)
    }

    private func heroStat(value: String, label: String, showDivider: Bool) -> some View {
        HStack(spacing: 10) {
            if showDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(AppTheme.rounded(22, .heavy))
                Text(label).font(AppTheme.rounded(11, .bold)).opacity(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    func menuDestination(for item: MenuItem, isIPad: Bool) -> some View {
        switch item.id {
        case "huruf":
            NavigationLink(destination: HiraganaView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "kanji":
            NavigationLink(destination: KanjiView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "flashcard":
            NavigationLink(destination: FlashcardTypeSelectionView(store: flashcardStore)) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "vocabulary":
            NavigationLink(destination: VocabularyView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "grammar":
            NavigationLink(destination: GrammarView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        default:
            NavigationLink(destination: ComingSoonView(featureName: item.label)) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        }
    }
}

// MARK: - Menu Card View
struct MenuCardView: View {
    let item: MenuItem
    var isIPad = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.tileIconRadius, style: .continuous)
                    .fill(LinearGradient(colors: item.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: item.icon)
                    .font(AppTheme.rounded(21, .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(AppTheme.rounded(15, .heavy))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                Text(item.sub)
                    .font(AppTheme.rounded(12, .semibold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 9, x: 0, y: 6)
    }
}

// MARK: - Preview
#Preview { ContentView() }

struct ComingSoonView: View {
    let featureName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hammer.fill")
                .font(AppTheme.rounded(44, .semibold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
            Text("\(featureName) Segera Hadir")
                .font(AppTheme.rounded(22, .heavy))
                .foregroundColor(AppTheme.primaryText(colorScheme))
            Text("Fitur ini sedang dikembangkan.")
                .font(AppTheme.rounded(14, .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.screenBackground(colorScheme).ignoresSafeArea())
        .navigationTitle(featureName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
