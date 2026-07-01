import Foundation

/// Owns the live timer that fires the next workout prompt. Slot maths lives in the
/// pure `SlotPlanner`; this class just schedules a one-shot timer and reschedules
/// after each fire, snooze, or settings change.
@MainActor
final class WorkoutScheduler: ObservableObject {
    @Published private(set) var nextFireDate: Date?

    var params = SchedulingParams()
    /// Injected so the scheduler can skip meeting times without importing EventKit here.
    var isBusy: (Date) -> Bool = { _ in false }
    var onFire: () -> Void = {}

    private var timer: Timer?

    /// Recompute and arm the next prompt. `paused` short-circuits (e.g. "Pause today").
    func reschedule(now: Date = .now, paused: Bool = false) {
        timer?.invalidate()
        timer = nil

        guard !paused else {
            nextFireDate = nil
            return
        }

        let next = SlotPlanner.nextSlot(
            after: now,
            params: params,
            randomOffset: { maxJitter in maxJitter <= 0 ? 0 : Double.random(in: -maxJitter...maxJitter) },
            isBusy: isBusy
        )
        nextFireDate = next
        guard let next else { return }

        let interval = max(1, next.timeIntervalSinceNow)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.onFire() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Push the next prompt out by a fixed delay (used by "Snooze").
    func snooze(minutes: Int) {
        reschedule(now: Date().addingTimeInterval(Double(minutes) * 60))
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        nextFireDate = nil
    }
}
