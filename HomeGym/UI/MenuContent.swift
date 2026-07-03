import SwiftUI

/// The menu-bar dropdown (window style): status line + quick actions.
struct MenuContent: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HomeGym")
                .font(.headline)

            statusLine
            weeklyLine

            Divider()

            Button {
                coordinator.startWorkoutNow()
            } label: {
                Label("Do a workout now", systemImage: "bolt.fill")
            }

            if coordinator.isPausedNow {
                Button {
                    coordinator.resume()
                } label: {
                    Label("Resume prompts", systemImage: "play.fill")
                }
            } else {
                Button {
                    coordinator.pauseForToday()
                } label: {
                    Label("Pause for today", systemImage: "pause.fill")
                }
            }

            Divider()

            Button {
                openHostedWindow("history")
            } label: {
                Label("History & Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            Button {
                openHostedWindow("settings")
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit HomeGym", systemImage: "power")
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .frame(width: 240, alignment: .leading)
    }

    private var weeklyLine: some View {
        let count = coordinator.completedThisWeekCount()
        return Label("\(count) workout\(count == 1 ? "" : "s") this week", systemImage: "flame")
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var statusLine: some View {
        if coordinator.isPausedNow {
            Label("Paused until tomorrow", systemImage: "moon.zzz")
                .foregroundStyle(.secondary)
        } else if let next = coordinator.scheduler.nextFireDate {
            Label("Next: \(next.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                .foregroundStyle(.secondary)
        } else {
            Label("No workout scheduled", systemImage: "clock.badge.questionmark")
                .foregroundStyle(.secondary)
        }
    }

    private func openHostedWindow(_ id: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: id)
    }
}
