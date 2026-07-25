import SwiftUI

struct SettingsView: View {
    @ObservedObject private var account = AccountStore.shared
    @AppStorage("daily_target") private var dailyTarget = 20
    @AppStorage("notif_enabled") private var notifEnabled = false
    @AppStorage("notif_hour") private var notifHour = 20

    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) private var scheme

    @State private var showResetAlert = false
    @State private var resetDone = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pengaturan")
                        .font(AppTheme.rounded(32, .heavy))
                        .foregroundColor(AppTheme.primaryText(scheme))
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    section("PREFERENSI") { preferencesCard }
                    SettingsFooter(text: "Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.")

                    section("DATA BELAJAR") { dataCard }
                    SettingsFooter(text: "Reset hanya menghapus progres flashcard lokal, review log, streak, dan pengaturan FSRS.")

                    section("SEGERA HADIR") { comingSoonCard }
                }
                .padding(.bottom, 24)
            }
            .background(AppTheme.screenBackground(scheme).ignoresSafeArea())
            .navigationBarHidden(true)
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
        .navigationViewStyle(.stack)
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

    // MARK: - Data belajar

    private var dataCard: some View {
        SettingsCard {
            Button { showResetAlert = true } label: {
                SettingsRow(icon: "trash.fill",
                            colors: [Color(hex: 0xFF7A70), Color(hex: 0xFF3B30)],
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
                          colors: [Color(hex: 0x7C93FF), AppTheme.indigoDeep],
                          title: "Sinkronisasi otomatis",
                          showsDivider: false)
        }
    }

    private func comingSoonRow(icon: String, colors: [Color], title: String, showsDivider: Bool = true) -> some View {
        SettingsRow(icon: icon, colors: colors, title: title, showsDivider: showsDivider) {
            Text("coming soon")
                .font(AppTheme.rounded(14, .semibold))
                .foregroundColor(AppTheme.secondaryText(scheme))
        }
    }
}

#Preview {
    SettingsView()
}
