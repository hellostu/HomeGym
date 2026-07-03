import SwiftUI
import SwiftData

@main
struct HomeGymApp: App {
    private let container: ModelContainer
    @StateObject private var coordinator: AppCoordinator

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Exercise.self, WorkoutSet.self, SnackSession.self, AppSettings.self
            )
        } catch {
            fatalError("Failed to create the HomeGym data store: \(error)")
        }
        self.container = container
        _coordinator = StateObject(wrappedValue: AppCoordinator(context: container.mainContext))
    }

    var body: some Scene {
        MenuBarExtra("HomeGym", systemImage: "dumbbell.fill") {
            MenuContent()
                .environmentObject(coordinator)
                .modelContainer(container)
                .task { coordinator.bootstrap() }
        }
        .menuBarExtraStyle(.window)

        Window("History & Progress", id: "history") {
            HistoryView()
                .environmentObject(coordinator)
                .modelContainer(container)
        }
        .defaultSize(width: 760, height: 580)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(coordinator)
                .modelContainer(container)
        }
        .defaultSize(width: 460, height: 520)
    }
}
