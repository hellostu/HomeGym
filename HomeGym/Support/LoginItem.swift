import Foundation
import ServiceManagement

/// Wraps `SMAppService` so HomeGym can start automatically at login — key for a
/// menu-bar app whose whole value is being there without you opening it.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers/unregisters the app as a login item. Returns false if it failed.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
