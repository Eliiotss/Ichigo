import SwiftUI

struct SettingsView: View {
    @AppStorage("user_name") private var userName = "User123"
    @AppStorage("user_email") private var userEmail = ""
    @AppStorage("daily_target") private var dailyTarget = 20
    @AppStorage("notif_enabled") private var notifEnabled = false
    @AppStorage("notif_hour") private var notifHour = 20
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showResetAlert = false
    @State private var resetDone = false
    @State private var showPermissionDeniedAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Akun
                Section {
                    HStack {
                        Label("Nama Pengguna", systemImage: "person")
                        Spacer()
                        TextField("User123", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        TextField("email@contoh.com", text: $userEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Akun")
                } footer: {
                    Text("Nama akan tampil di halaman utama. Email digunakan untuk sinkronisasi dan menyimpan progress belajar kamu (segera hadir).")
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
                
                // MARK: - Roadmap
                Section {
                    Label("Sync akun ke cloud (coming soon)", systemImage: "icloud")
                    Label("Backup/restore lokal (coming soon)", systemImage: "externaldrive")
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
            .onAppear {
                notificationManager.checkAuthorization()
            }
        }
    }
}

#Preview {
    SettingsView()
}

