import SwiftUI
import EventKit
import UserNotifications

/// Settings: work hours, frequency, muscle-group selection, and permissions.
struct SettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        SettingsForm(settings: coordinator.settings)
            .environmentObject(coordinator)
            .frame(width: 460)
    }
}

private struct SettingsForm: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Bindable var settings: AppSettings
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Start HomeGym at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if !LoginItem.setEnabled(newValue) {
                            launchAtLogin = LoginItem.isEnabled   // revert if it failed
                        }
                    }
            }

            Section("When to prompt") {
                Stepper("Work starts at \(settings.workStartHour):00",
                        value: $settings.workStartHour, in: 0...23)
                Stepper("Work ends at \(settings.workEndHour):00",
                        value: $settings.workEndHour, in: 1...24)
                Stepper("Workouts per day: \(settings.targetWorkoutsPerDay)",
                        value: $settings.targetWorkoutsPerDay, in: 1...8)
                Stepper("Minimum gap: \(settings.minGapMinutes) min",
                        value: $settings.minGapMinutes, in: 15...240, step: 15)
                Toggle("Weekdays only", isOn: $settings.weekdaysOnly)
                Toggle("Skip prompts during calendar meetings", isOn: $settings.calendarBusyIsBlocking)
            }

            Section("Between sets") {
                Stepper("Rest timer: \(settings.restSeconds)s",
                        value: $settings.restSeconds, in: 15...300, step: 15)
            }

            Section("Muscle groups") {
                ForEach(MuscleGroup.allCases) { group in
                    Toggle(group.displayName, isOn: binding(for: group))
                }
            }

            Section("Permissions") {
                permissionRow(
                    title: "Calendar",
                    granted: coordinator.calendar.hasAccess,
                    action: { Task { await coordinator.calendar.requestAccess() } }
                )
                permissionRow(
                    title: "Notifications",
                    granted: coordinator.notifications.authorization == .authorized,
                    action: { Task { await coordinator.notifications.requestAccess() } }
                )
            }
        }
        .formStyle(.grouped)
        .onChange(of: schedulingSignature) { coordinator.reloadSchedule() }
    }

    /// Any value that affects scheduling — recompute the next prompt when it changes.
    private var schedulingSignature: String {
        "\(settings.workStartHour)-\(settings.workEndHour)-\(settings.targetWorkoutsPerDay)-\(settings.minGapMinutes)-\(settings.weekdaysOnly)-\(settings.enabledMuscleGroupsRaw.sorted().joined())"
    }

    private func binding(for group: MuscleGroup) -> Binding<Bool> {
        Binding(
            get: { settings.enabledMuscleGroups.contains(group) },
            set: { isOn in
                var groups = settings.enabledMuscleGroups
                if isOn { groups.insert(group) } else { groups.remove(group) }
                settings.enabledMuscleGroups = groups
            }
        )
    }

    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            if granted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant access", action: action)
            }
        }
    }
}
