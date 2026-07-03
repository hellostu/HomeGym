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
            todayProgress
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

    private var todayProgress: some View {
        let done = coordinator.completedTodayCount()
        let target = coordinator.dailyTarget
        let hitTarget = done >= target
        return HStack(spacing: 8) {
            Image(systemName: hitTarget ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(hitTarget ? .green : .secondary)
            Text("Today: \(done) / \(target)")
                .foregroundStyle(hitTarget ? .primary : .secondary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<max(target, done), id: \.self) { index in
                    Circle()
                        .fill(index < done ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .font(.subheadline)
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
        } else if coordinator.dailyGoalMet {
            Label("Goal reached — done for today 🎉", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
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
