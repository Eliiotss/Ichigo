import SwiftUI

struct SettingsView: View {
    @ObservedObject private var account = AccountStore.shared
    @AppStorage("daily_target") private var dailyTarget = 20
    @AppStorage("notif_enabled") private var notifEnabled = false
    @AppStorage("notif_hour") private var notifHour = 20
    @AppStorage(AppAppearance.storageKey) private var appearanceRawValue = AppAppearance.system.rawValue

    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) private var scheme

    @State private var showResetAlert = false
    @State private var resetDone = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pengaturan")
                        .font(AppTheme.rounded(32, .heavy))
                        .foregroundStyle(AppTheme.primaryText(scheme))
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    section("PREFERENSI") { preferencesCard }
                    SettingsFooter(text: "Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.")

                    section("DATA BELAJAR") { dataCard }
                    SettingsFooter(text: "Reset hanya menghapus progres flashcard lokal, review log, streak, dan pengaturan FSRS.")

                    section("SEGERA HADIR") { comingSoonCard }
                }
                .padding(.bottom, AppTheme.screenBottomPadding)
            }
            .background(AppTheme.screenBackground(scheme).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert("Reset progress flashcard?", isPresented: $showResetAlert) {
                Button("Batal", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    FlashcardDataResetter.resetAll()
                    account.reload()
                    resetDone = true
                }
            } message: {
                Text("Tindakan ini tidak bisa dibatalkan. Data Kanji, Grammar, Vocabulary, dan file JSON tidak akan dihapus.")
            }
            .alert("Progress berhasil direset", isPresented: $resetDone) {
                Button("OK", role: .cancel) {}
            }
            .alert("Izin notifikasi ditolak", isPresented: $showPermissionDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Aktifkan izin notifikasi di Pengaturan iPhone > Notifikasi > Ichigo untuk menggunakan fitur pengingat.")
            }
            .onAppear { notificationManager.checkAuthorization() }
        }
    }

    /// Jembatan antara sakelar geser (Bool) dan pilihan tersimpan.
    ///
    /// Nilai tampilnya diambil dari `scheme`, yaitu skema warna efektif setelah
    /// `RootView` menerapkan pilihan — jadi saat pilihan masih "Ikuti Sistem",
    /// sakelar mengikuti tampilan perangkat. Sekali digeser, pilihannya menjadi
    /// eksplisit terang atau gelap.
    private var isDarkBinding: Binding<Bool> {
        Binding(
            get: { scheme == .dark },
            set: { newValue in
                appearanceRawValue = (newValue ? AppAppearance.dark : AppAppearance.light).rawValue
            }
        )
    }

    // MARK: - Section wrapper

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionLabel(text: title)
            content()
        }
        .padding(.top, 14)
    }

    // MARK: - Preferensi

    private var preferencesCard: some View {
        SettingsCard {
            SettingsRow(icon: scheme == .dark ? "moon.fill" : "sun.max.fill",
                        colors: [AppTheme.indigoSoft, AppTheme.indigoDeep],
                        title: "Mode Tampilan") {
                ThemeSlideToggle(isDark: isDarkBinding)
            }

            SettingsRow(icon: "bell.fill", colors: [AppTheme.indigo, AppTheme.indigoDeep], title: "Pengingat Belajar") {
                Toggle("", isOn: $notifEnabled)
                    .labelsHidden()
                    .tint(AppTheme.accent)
                    .onChange(of: notifEnabled) { _, isOn in
                        if isOn {
                            notificationManager.requestPermission { granted in
                                if granted {
                                    notificationManager.scheduleDailyReminder(hour: notifHour)
                                } else {
                                    notifEnabled = false
                                    showPermissionDeniedAlert = true
                                }
                            }
                        } else {
                            notificationManager.cancelReminder()
                        }
                    }
            }

            if notifEnabled {
                SettingsRow(icon: "clock.fill", colors: [AppTheme.teal, AppTheme.tealDeep], title: "Waktu pengingat") {
                    Stepper("jam \(notifHour):00", value: $notifHour, in: 6...23)
                        .font(AppTheme.rounded(14, .semibold))
                        .foregroundStyle(AppTheme.secondaryText(scheme))
                        .fixedSize()
                        .onChange(of: notifHour) { _, newHour in
                            notificationManager.scheduleDailyReminder(hour: newHour)
                        }
                }
            }

            SettingsRow(icon: "target", colors: [AppTheme.violet, AppTheme.violetDeep], title: "Target Harian") {
                Stepper("\(dailyTarget) kartu", value: $dailyTarget, in: 5...200, step: 5)
                    .font(AppTheme.rounded(14, .semibold))
                    .foregroundStyle(AppTheme.secondaryText(scheme))
                    .fixedSize()
            }

            SettingsRow(icon: "globe", colors: [AppTheme.blue, AppTheme.indigoDeep], title: "Bahasa", showsDivider: false) {
                Text("Bahasa Indonesia")
                    .font(AppTheme.rounded(16, .semibold))
                    .foregroundStyle(AppTheme.secondaryText(scheme))
            }
        }
    }

    // MARK: - Data belajar

    private var dataCard: some View {
        SettingsCard {
            Button { showResetAlert = true } label: {
                SettingsRow(icon: "trash.fill",
                            colors: [AppTheme.dangerSoft, AppTheme.danger],
                            title: "Reset Semua Progress Flashcard", showsDivider: false) { EmptyView() }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Segera hadir

    /// Account, cloud backup and sync are intentionally parked for a later
    /// release. Their implementation lives under `Backup/` and is not wired up
    /// yet, so the UI advertises them as upcoming rather than exposing controls
    /// that cannot be completed.
    private var comingSoonCard: some View {
        SettingsCard {
            comingSoonRow(icon: "person.crop.circle.fill",
                          colors: [AppTheme.blueLight, AppTheme.blue],
                          title: "Akun")
            comingSoonRow(icon: "externaldrive.fill",
                          colors: [AppTheme.teal, AppTheme.tealDeep],
                          title: "Cadangkan & Pulihkan")
            comingSoonRow(icon: "icloud.fill",
                          colors: [AppTheme.indigoSoft, AppTheme.indigoDeep],
                          title: "Sinkronisasi otomatis",
                          showsDivider: false)
        }
    }

    private func comingSoonRow(icon: String, colors: [Color], title: String, showsDivider: Bool = true) -> some View {
        SettingsRow(icon: icon, colors: colors, title: title, showsDivider: showsDivider) {
            Text("coming soon")
                .font(AppTheme.rounded(14, .semibold))
                .foregroundStyle(AppTheme.secondaryText(scheme))
        }
    }
}

#Preview {
    SettingsView()
}

// MARK: - Settings building blocks

/// Uppercase section label above a settings card.
struct SettingsSectionLabel: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(12, .heavy))
            .kerning(0.6)
            .foregroundStyle(AppTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

/// Rounded white card that groups settings rows.
struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) { content }
            .background(AppTheme.surface(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.cardShadow(scheme), radius: 7, x: 0, y: 4)
            .padding(.horizontal, 18)
    }
}

/// Small gradient icon chip used at the leading edge of a settings row.
struct SettingsIcon: View {
    let systemName: String
    let colors: [Color]

    var body: some View {
        Image(systemName: systemName)
            .font(AppTheme.rounded(14, .semibold))
            .foregroundStyle(.white)
            .frame(width: 29, height: 29)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// A settings row: gradient icon, title and trailing content, with an optional
/// hairline separator matching the design's inset divider.
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let colors: [Color]
    let title: String
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, colors: colors)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(AppTheme.rounded(16, .semibold))
                        .foregroundStyle(AppTheme.primaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    trailing
                }
                .padding(.vertical, 11)

                if showsDivider {
                    Rectangle()
                        .fill(AppTheme.trackColor(scheme))
                        .frame(height: 1)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
}

/// Explanatory footer under a settings card.
struct SettingsFooter: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(12, .medium))
            .foregroundStyle(AppTheme.secondaryText(scheme))
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}
