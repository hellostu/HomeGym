import Foundation
import EventKit

/// Wraps EventKit so the scheduler can ask "am I in a meeting right now?" and never
/// interrupt one. Requires the Calendars entitlement + usage string (see Info.plist).
@MainActor
final class CalendarService: ObservableObject {
    private let store = EKEventStore()

    @Published private(set) var authorization: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

    var hasAccess: Bool {
        if #available(macOS 14.0, *) {
            return authorization == .fullAccess
        } else {
            return authorization == .authorized
        }
    }

    func refreshAuthorization() {
        authorization = EKEventStore.authorizationStatus(for: .event)
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            refreshAuthorization()
            return granted
        } catch {
            refreshAuthorization()
            return false
        }
    }

    /// Is there a busy (non all-day, not cancelled, not declined) event overlapping
    /// the short window starting at `date`? Returns false if we lack access, so a
    /// missing permission never blocks workouts entirely.
    func isBusy(at date: Date, window: TimeInterval = 300) -> Bool {
        guard hasAccess else { return false }
        let predicate = store.predicateForEvents(withStart: date, end: date.addingTimeInterval(window), calendars: nil)
        return store.events(matching: predicate).contains { event in
            guard !event.isAllDay, event.status != .canceled else { return false }
            return !isDeclined(event)
        }
    }

    /// The end of the busy event covering `date`, if any — used to defer a prompt to
    /// just after a meeting instead of skipping it.
    func busyEndDate(at date: Date, window: TimeInterval = 4 * 3600) -> Date? {
        guard hasAccess else { return nil }
        let predicate = store.predicateForEvents(withStart: date, end: date.addingTimeInterval(window), calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.status != .canceled && !isDeclined($0) && $0.startDate <= date && $0.endDate > date }
            .map(\.endDate)
            .max()
    }

    private func isDeclined(_ event: EKEvent) -> Bool {
        event.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false
    }
}
