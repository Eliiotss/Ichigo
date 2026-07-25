import SwiftUI

struct SettingsView: View {
    @ObservedObject private var account = AccountStore.shared
    @AppStorage("daily_target") private var dailyTarget = 20
    @AppStorage("notif_enabled") private var notifEnabled = false
    @AppStorage("notif_hour") private var notifHour = 20
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var backup = DriveBackupManager()
    @State private var showResetAlert = false
    @State private var resetDone = false
    @State private var showPermissionDeniedAlert = false
    @State private var showRestoreConfirm = false

    var body: some View {
        NavigationView {
            List {
                // MARK: - Akun
                Section {
                    HStack {
                        Label("Nama Pengguna", systemImage: "person")
                        Spacer()
                        TextField("User123", text: $account.displayName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        TextField("email@contoh.com", text: $account.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Akun")
                } footer: {
                    Text("Nama akan tampil di halaman utama. Email bersifat opsional untuk identitas profil. Cadangan progres tersedia lewat Google Drive di bagian bawah.")
                }
                
                // MARK: - Preferensi
                Section {
                    Toggle(isOn: $notifEnabled) {
                        Label("Pengingat Belajar", systemImage: "bell")
                    }
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
                    
                    if notifEnabled {
                        Stepper(
                            "Waktu pengingat: jam \(notifHour):00",
                            value: $notifHour,
                            in: 6...23
                        )
                        .onChange(of: notifHour) { _, newHour in
                            notificationManager.scheduleDailyReminder(hour: newHour)
                        }
                    }
                    
                    HStack {
                        Label("Bahasa", systemImage: "globe")
                        Spacer()
                        Text("Bahasa Indonesia")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("Target Harian: \(dailyTarget) kartu", value: $dailyTarget, in: 5...200, step: 5)
                } header: {
                    Text("Preferensi")
                } footer: {
                    Text("Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.")
                }
                
                // MARK: - Data Belajar
                Section {
                    Button(role: .destructive) { showResetAlert = true } label: {
                        Label("Reset Semua Progress Flashcard", systemImage: "trash")
                    }
                    Text("Reset hanya menghapus progress lokal flashcard, review log, streak, dan pengaturan FSRS.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Data Belajar")
                }
                
                // MARK: - Cadangan (Google Drive)
                backupSection

                // MARK: - Roadmap
                Section {
                    Label("Sinkronisasi otomatis (coming soon)", systemImage: "icloud")
                } header: {
                    Text("Roadmap")
                }
            }
            .navigationTitle("Pengaturan")
            .alert("Reset progress flashcard?", isPresented: $showResetAlert) {
                Button("Batal", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    FlashcardDataResetter.resetAll()
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
            .onAppear {
                notificationManager.checkAuthorization()
            }
        }
    }

    // MARK: - Backup section

    @ViewBuilder private var backupSection: some View {
        Section {
            if !backup.isConfigured {
                Label("Belum dikonfigurasi", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.secondary)
                Text("Tambahkan file GoogleOAuth.plist berisi CLIENT_ID OAuth iOS Anda untuk mengaktifkan backup. Panduan: docs/GoogleDriveBackup.md.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else if !backup.isSignedIn {
                Button {
                    Task { await backup.signIn() }
                } label: {
                    Label("Masuk dengan Google", systemImage: "person.crop.circle.badge.plus")
                }
                .disabled(backup.isBusy)
            } else {
                Button {
                    Task { await backup.backupNow() }
                } label: {
                    Label("Backup sekarang", systemImage: "arrow.up.doc")
                }
                .disabled(backup.isBusy)

                Button {
                    showRestoreConfirm = true
                } label: {
                    Label("Pulihkan dari Drive", systemImage: "arrow.down.doc")
                }
                .disabled(backup.isBusy)

                if let linked = backup.linkedAccountEmail {
                    HStack {
                        Label("Akun", systemImage: "person.crop.circle")
                        Spacer()
                        Text(linked)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                if let date = backup.lastBackupDate {
                    Text("Cadangan terakhir: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    backup.signOut()
                } label: {
                    Label("Keluar dari Google", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .disabled(backup.isBusy)
            }

            backupStatusRow
        } header: {
            Text("Cadangan (Google Drive)")
        } footer: {
            Text("Backup manual progres belajar ke folder khusus aplikasi (appDataFolder) di Google Drive Anda — hanya aplikasi ini yang bisa mengaksesnya.")
        }
    }

    @ViewBuilder private var backupStatusRow: some View {
        switch backup.phase {
        case .idle:
            EmptyView()
        case .working(let message):
            HStack(spacing: 8) {
                ProgressView()
                Text(message).font(.footnote).foregroundColor(.secondary)
            }
        case .success(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundColor(.green)
        case .failure(let message):
            Label(message, systemImage: "xmark.octagon.fill")
                .font(.footnote)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    SettingsView()
}

