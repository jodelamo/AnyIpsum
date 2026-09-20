import UserNotifications

final class CopyNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func notifyCopied(wordCount: Int) {
        Task {
            do {
                let settings = await center.notificationSettings()
                let isAuthorized: Bool

                if settings.authorizationStatus == .notDetermined {
                    isAuthorized = try await center.requestAuthorization(options: [.alert])
                } else {
                    isAuthorized = settings.authorizationStatus == .authorized
                }

                guard isAuthorized else { return }

                let content = UNMutableNotificationContent()
                content.body = Self.message(wordCount: wordCount)
                try await center.add(UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                ))
            } catch {
                // Copying should still succeed if notifications are unavailable.
            }
        }
    }

    static func message(wordCount: Int) -> String {
        "Copied \(wordCount) \(wordCount == 1 ? "word" : "words")"
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(.banner)
    }
}
