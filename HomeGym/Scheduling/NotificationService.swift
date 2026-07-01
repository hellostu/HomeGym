import Foundation
import UserNotifications

/// Thin wrapper over UserNotifications. The banner is a fallback nudge — the primary
/// prompt is the floating window — so failures here are non-fatal.
@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorization = settings.authorizationStatus
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await refreshAuthorization()
            return granted
        } catch {
            await refreshAuthorization()
            return false
        }
    }

    func postWorkoutPrompt(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "homegym.prompt",
            content: content,
            trigger: nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
