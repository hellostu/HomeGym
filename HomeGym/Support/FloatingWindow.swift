import AppKit
import SwiftUI

/// Hosts the workout prompt in a floating panel that pops to the front over whatever
/// Stu is working on — the core "just get a popup" behaviour.
@MainActor
final class WorkoutWindowController {
    private var window: NSWindow?

    func show(coordinator: AppCoordinator) {
        // Reuse the window if it's already up.
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: WorkoutPopupView().environmentObject(coordinator)
        )

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.title = "Time for a Snack Workout"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 380, height: 540))
        window.center()

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
    }
}
