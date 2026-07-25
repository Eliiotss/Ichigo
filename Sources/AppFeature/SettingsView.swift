import SwiftUI

struct SettingsView: View {
    @ObservedObject private var account = AccountStore.shared
    @AppStorage("daily_target") private var dailyTarget = 20
    @AppStorage("notif_enabled") private var notifEnabled = false
    @AppStorage("notif_hour") private var notifHour = 20

    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var backup = DriveBackupManager()
    @Environment(\.colorScheme) private var scheme

    @State private var showResetAlert = false
    @State private var resetDone = false
    @State private var showPermissionDeniedAlert = false
    @State private var showRestoreConfirm = false

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

                    section("AKUN") { accountCard }
                    SettingsFooter(text: "Nama akan tampil di halaman utama. Email bersifat opsional untuk identitas profil. Cadangan progres tersedia lewat Google Drive di bawah.")

                    section("PREFERENSI") { preferencesCard }
                    SettingsFooter(text: "Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.")

                    section("CADANGAN (GOOGLE DRIVE)") { backupCard }
                    SettingsFooter(text: "Backup manual progres belajar ke folder khusus aplikasi (appDataFolder) di Google Drive Anda — hanya aplikasi ini yang bisa mengaksesnya.")

                    section("DATA BELAJAR") { dataCard }

                    section("ROADMAP") { roadmapCard }
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
            .alert("Pulihkan dari Google Drive?", isPresented: $showRestoreConfirm) {
                Button("Batal", role: .cancel) {}
                Button("Pulihkan", role: .destructive) { Task { await backup.restoreNow() } }
            } message: {
                Text("Progres lokal saat ini akan ditimpa oleh cadangan dari Drive. Tindakan ini tidak bisa dibatalkan.")
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

    // MARK: - Akun

    private var accountCard: some View {
        SettingsCard {
            SettingsRow(icon: "person.fill", colors: [AppTheme.blueLight, AppTheme.blue], title: "Nama Pengguna") {
                TextField("User123", text: $account.displayName)
                    .font(AppTheme.rounded(16, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
                    .multilineTextAlignment(.trailing)
            }
            SettingsRow(icon: "envelope.fill", colors: [AppTheme.sky, AppTheme.skyDeep], title: "Email", showsDivider: false) {
                TextField("email@contoh.com", text: $account.email)
                    .font(AppTheme.rounded(16, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Preferensi

    private var preferencesCard: some View {
        SettingsCard {
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
                        .foregroundColor(AppTheme.secondaryText(scheme))
                        .fixedSize()
                        .onChange(of: notifHour) { _, newHour in
                            notificationManager.scheduleDailyReminder(hour: newHour)
                        }
                }
            }

            SettingsRow(icon: "target", colors: [AppTheme.violet, AppTheme.violetDeep], title: "Target Harian") {
                Stepper("\(dailyTarget) kartu", value: $dailyTarget, in: 5...200, step: 5)
                    .font(AppTheme.rounded(14, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
                    .fixedSize()
            }

            SettingsRow(icon: "globe", colors: [AppTheme.blue, AppTheme.indigoDeep], title: "Bahasa", showsDivider: false) {
                Text("Bahasa Indonesia")
                    .font(AppTheme.rounded(16, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
            }
        }
    }

    // MARK: - Cadangan

    private var backupCard: some View {
        SettingsCard {
            if !backup.isConfigured {
                SettingsRow(icon: "exclamationmark.triangle.fill",
                            colors: [Color(hex: 0xFFB35C), Color(hex: 0xFF9500)],
                            title: "Belum dikonfigurasi", showsDivider: false) {
                    Text("GoogleOAuth.plist")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundColor(AppTheme.secondaryText(scheme))
                }
            } else if !backup.isSignedIn {
                Button {
                    Task { await backup.signIn() }
                } label: {
                    SettingsRow(icon: "person.crop.circle.badge.plus",
                                colors: [AppTheme.blueLight, AppTheme.blue],
                                title: "Masuk dengan Google", showsDivider: false) { EmptyView() }
                }
                .buttonStyle(.plain)
                .disabled(backup.isBusy)
            } else {
                if let linked = backup.linkedAccountEmail {
                    SettingsRow(icon: "person.crop.circle.fill",
                                colors: [AppTheme.blueLight, AppTheme.blue], title: "Akun") {
                        Text(linked)
                            .font(AppTheme.rounded(13, .semibold))
                            .foregroundColor(AppTheme.secondaryText(scheme))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Button { Task { await backup.backupNow() } } label: {
                    SettingsRow(icon: "arrow.up.doc.fill", colors: [AppTheme.teal, AppTheme.tealDeep],
                                title: "Backup sekarang") { EmptyView() }
                }
                .buttonStyle(.plain)
                .disabled(backup.isBusy)

                Button { showRestoreConfirm = true } label: {
                    SettingsRow(icon: "arrow.down.doc.fill", colors: [AppTheme.sky, AppTheme.skyDeep],
                                title: "Pulihkan dari Drive") { EmptyView() }
                }
                .buttonStyle(.plain)
                .disabled(backup.isBusy)

                if let date = backup.lastBackupDate {
                    SettingsRow(icon: "clock.arrow.circlepath", colors: [AppTheme.indigo, AppTheme.indigoDeep],
                                title: "Cadangan terakhir") {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.rounded(13, .semibold))
                            .foregroundColor(AppTheme.secondaryText(scheme))
                    }
                }

                Button { backup.signOut() } label: {
                    SettingsRow(icon: "rectangle.portrait.and.arrow.right",
                                colors: [Color(hex: 0xFF7A70), Color(hex: 0xFF3B30)],
                                title: "Keluar dari Google", showsDivider: false) { EmptyView() }
                }
                .buttonStyle(.plain)
                .disabled(backup.isBusy)
            }

            backupStatusRow
        }
    }

    @ViewBuilder private var backupStatusRow: some View {
        switch backup.phase {
        case .idle:
            EmptyView()
        case .working(let message):
            statusLine(message, systemImage: nil, tint: AppTheme.secondaryText(scheme), showsSpinner: true)
        case .success(let message):
            statusLine(message, systemImage: "checkmark.circle.fill", tint: Color(hex: 0x22B981), showsSpinner: false)
        case .failure(let message):
            statusLine(message, systemImage: "xmark.octagon.fill", tint: Color(hex: 0xFF3B30), showsSpinner: false)
        }
    }

    private func statusLine(_ message: String, systemImage: String?, tint: Color, showsSpinner: Bool) -> some View {
        HStack(spacing: 8) {
            if showsSpinner { ProgressView() }
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 13, weight: .bold)).foregroundColor(tint)
            }
            Text(message)
                .font(AppTheme.rounded(12, .semibold))
                .foregroundColor(tint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
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

    // MARK: - Roadmap

    private var roadmapCard: some View {
        SettingsCard {
            SettingsRow(icon: "icloud.fill", colors: [Color(hex: 0x7C93FF), AppTheme.indigoDeep],
                        title: "Sinkronisasi otomatis", showsDivider: false) {
                Text("coming soon")
                    .font(AppTheme.rounded(14, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
            }
        }
    }
}

#Preview {
    SettingsView()
}
