import Foundation
import UserNotifications
import os

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

        center.add(request) { error in
            if let error {
                Log.notifications.error("Failed to schedule daily reminder: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }
}

