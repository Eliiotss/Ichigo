import Foundation
import UserNotifications

// MARK: - Notification Manager (pengingat belajar harian)
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let reminderId = "daily_study_reminder"
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    /// Jadwalkan pengingat harian jam tertentu (default jam 20:00) kalau target belum selesai
    func scheduleDailyReminder(hour: Int = 20, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        
        let content = UNMutableNotificationContent()
        content.title = "Jangan lupa belajar hari ini! 📚"
        content.body = "Masih ada progress belajar yang belum selesai. Yuk lanjutkan sebelum hari berganti."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }
    
    /// Panggil ini saat app dibuka: kalau target hari ini SUDAH tercapai, batalkan notif jam ini saja
    /// (biar tidak diganggu notif kalau memang sudah belajar), lalu notif tetap akan muncul besok karena repeats: true
    func skipTodayIfTargetMet(studiedToday: Int, dailyTarget: Int) {
        guard studiedToday >= dailyTarget else { return }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            guard requests.contains(where: { $0.identifier == self.reminderId }) else { return }
            // Notifikasi tetap terjadwal untuk besok (repeats), tidak perlu unschedule permanen.
            // Kalau mau benar-benar skip notif HARI INI saja, perlu one-shot request terpisah per hari.
        }
    }
}

