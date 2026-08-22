import SwiftUI

/// The app's root view. It shows a splash screen while core resources are
/// pre-warmed, then cross-fades to the main tab interface.
///
/// This is the single public entry point of the `AppFeature` library; the
/// executable target hosts it inside a `WindowGroup`.
public struct RootView: View {
    @StateObject private var loadingState = AppLoadingState()

    /// Mode tampilan pilihan pengguna. Dipasang di akar supaya seluruh layar,
    /// termasuk lembar yang muncul di atasnya, ikut berubah sekaligus.
    @AppStorage(AppAppearance.storageKey) private var appearanceRawValue = AppAppearance.system.rawValue

    public init() {}

    private var appearance: AppAppearance { .from(storedValue: appearanceRawValue) }

    public var body: some View {
        ZStack {
            ContentView()
                .opacity(loadingState.isReady ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: loadingState.isReady)

            if !loadingState.isReady {
                SplashView(statusText: loadingState.statusText, progress: loadingState.progress)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(appearance.preferredColorScheme)
        .task {
            await loadingState.prepare()
        }
    }
}

@MainActor
final class AppLoadingState: ObservableObject {
    @Published var isReady = false
    @Published var statusText = "Menyiapkan aplikasi…"
    /// Bagian pekerjaan yang sudah selesai, 0 sampai 1. Nilainya naik setiap
    /// satu dataset selesai dibaca, jadi bilah di layar pembuka menunjukkan
    /// kemajuan yang sebenarnya, bukan animasi hiasan.
    @Published var progress: Double = 0

    private var hasPrepared = false

    /// Jeda terpendek layar pembuka. Tanpa ini, pada perangkat cepat splash
    /// hanya berkedip sepersekian detik dan terlihat seperti gangguan.
    private let minimumSplashSeconds = 0.65

    func prepare() async {
        guard !hasPrepared else { return }
        hasPrepared = true

        // Catat tanggal pemasangan pertama sekali saja. Ini jadi titik awal semua
        // hitungan harian (hari ini/due/streak) — hari pertama = hari install.
        AppInstallInfo.registerIfNeeded()

        let start = Date()
        await preloadCoreResources()

        statusText = "Hampir selesai…"

        let elapsed = Date().timeIntervalSince(start)
        if elapsed < minimumSplashSeconds {
            try? await Task.sleep(nanoseconds: UInt64((minimumSplashSeconds - elapsed) * 1_000_000_000))
        }

        withAnimation(.easeOut(duration: 0.25)) {
            isReady = true
        }
    }

    /// Membaca dataset level pertama lebih dulu supaya layar Beranda dan
    /// daftar-daftar tidak perlu menunggu pembacaan JSON saat dibuka. Hasilnya
    /// tersimpan di ``JSONResourceCache``, jadi pemanggilan berikutnya gratis.
    private func preloadCoreResources() async {
        statusText = "Memuat kanji…"
        await decodeOffMainThread { _ = try? JSONResourceCache.shared.decode([KanjiItem].self, filename: "KanjiN5") }
        advance(to: 0.25)

        statusText = "Memuat kosakata…"
        await decodeOffMainThread { _ = try? JSONResourceCache.shared.decode([VocabularyItem].self, filename: "VocabN5") }
        advance(to: 0.5)

        statusText = "Memuat tata bahasa…"
        await decodeOffMainThread { _ = try? JSONResourceCache.shared.decode([GrammarItem].self, filename: "GrammarN5") }
        advance(to: 0.75)

        statusText = "Memuat huruf kana…"
        await decodeOffMainThread { _ = try? JSONResourceCache.shared.decode([KanaGroupJSON].self, filename: "Hiragana") }
        advance(to: 1)
    }

    /// Menjalankan pembacaan di luar main thread supaya antarmuka tetap lancar.
    private func decodeOffMainThread(_ work: @escaping @Sendable () -> Void) async {
        await Task.detached(priority: .userInitiated) { work() }.value
    }

    private func advance(to value: Double) {
        withAnimation(.easeOut(duration: 0.25)) {
            progress = value
        }
    }
}

// MARK: - Info Pemasangan

/// Menyimpan tanggal pemasangan pertama aplikasi. Dipakai sebagai titik awal
/// hitungan harian ("hari ini"/"due"/streak) sehingga hari pertama = hari install.
/// Nilainya ditulis sekali dan tidak pernah ditimpa selama data lokal masih ada.
enum AppInstallInfo {
    static let firstInstallKey = "first_install_date_v1"

    /// Menstempel tanggal sekarang bila belum pernah tercatat.
    static func registerIfNeeded(date: Date = Date(), defaults: UserDefaults = .standard) {
        if defaults.object(forKey: firstInstallKey) == nil {
            defaults.set(date, forKey: firstInstallKey)
        }
    }

    /// Tanggal pemasangan pertama; jika belum ada, dianggap hari ini.
    static func firstInstallDate(defaults: UserDefaults = .standard) -> Date {
        defaults.object(forKey: firstInstallKey) as? Date ?? Date()
    }
}

// MARK: - Layar Pembuka

/// Layar pembuka: lambang aplikasi bergradien biru, nama aplikasi, lalu bilah
/// kemajuan pembacaan data di bagian bawah. Warnanya mengikuti tema aplikasi
/// agar peralihan ke Beranda tidak terasa melompat.
private struct SplashView: View {
    let statusText: String
    let progress: Double

    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            AppTheme.screenBackground(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                appMark

                Text("Ichigo")
                    .font(AppTheme.rounded(34, .heavy))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))
                    .padding(.top, 22)

                Text("Belajar bahasa Jepang")
                    .font(AppTheme.rounded(14, .medium))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    .padding(.top, 4)

                Spacer()

                progressSection
                    .padding(.horizontal, 48)
                    .padding(.bottom, 56)
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.35), value: hasAppeared)
        }
        .onAppear { hasAppeared = true }
    }

    private var appMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.blueLight, AppTheme.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)
                .shadow(color: AppTheme.blue.opacity(0.35), radius: 20, x: 0, y: 10)

            Text("🍓")
                .font(AppTheme.rounded(50))
        }
        .scaleEffect(hasAppeared ? 1 : 0.88)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: hasAppeared)
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.trackColor(colorScheme))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.blueLight, AppTheme.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)), height: 6)
                }
            }
            .frame(height: 6)

            Text(statusText)
                .font(AppTheme.rounded(13, .medium))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .animation(nil, value: statusText)
        }
    }
}

#Preview {
    RootView()
}
