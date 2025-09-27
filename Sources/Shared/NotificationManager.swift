import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter`. Safe to call from both app & extension, although permission requests should originate from the host app.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() { super.init() }

    func configureForAppLaunch() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error { print("Notification authorization error: \(error)") }
            if !granted { print("Notification permission not granted") }
        }
    }

    func scheduleDownloadReadyNotification(for record: BackgroundDownloadRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Yeet"
        content.body = "\(record.metadata.title) is ready to share"
        content.sound = .default
        content.userInfo = ["downloadID": record.id.uuidString]

        let request = UNNotificationRequest(identifier: record.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let idString = response.notification.request.content.userInfo["downloadID"] as? String,
           let id = UUID(uuidString: idString),
           let url = BackgroundDownloadManager.shared.completedFileURL(for: id) {
            DispatchQueue.main.async {
                AppContext.shared.presentShare(url: url)
            }
        }
        completionHandler()
    }
}
