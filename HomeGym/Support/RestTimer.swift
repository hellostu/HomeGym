import AppKit

/// Countdown rest timer used between sets. Remaining time is derived from a wall-clock
/// end date (so it stays accurate across ticks/sleep); the pure helpers are unit-tested.
@MainActor
final class RestTimer: ObservableObject {
    @Published private(set) var endDate: Date?
    @Published private(set) var tickNow: Date = Date()
    private(set) var duration: TimeInterval = 0
    private var timer: Timer?
    /// Preloaded and retained: an inline `NSSound(named:)?.play()` gets deallocated
    /// before the async playback starts, so it never actually chimes.
    private let chime = NSSound(named: "Glass")

    var remaining: TimeInterval { RestTimer.remaining(endDate: endDate, now: tickNow) }
    var isRunning: Bool { remaining > 0 }
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, (duration - remaining) / duration))
    }

    func start(seconds: Int) {
        let now = Date()
        tickNow = now
        duration = TimeInterval(seconds)
        endDate = now.addingTimeInterval(duration)
        startTicking()
    }

    /// Extend a running countdown (or start one if idle).
    func add(seconds: Int) {
        guard let endDate else { start(seconds: seconds); return }
        self.endDate = endDate.addingTimeInterval(TimeInterval(seconds))
        duration += TimeInterval(seconds)
        if timer == nil { startTicking() }
    }

    func stop() {
        endDate = nil
        timer?.invalidate()
        timer = nil
    }

    private func startTicking() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        tickNow = Date()
        if remaining <= 0 {
            timer?.invalidate()
            timer = nil
            playChime()
        }
    }

    private func playChime() {
        if let chime {
            chime.stop()   // rewind if it's somehow still playing
            chime.play()
        } else {
            NSSound.beep()
        }
    }

    // MARK: - Pure helpers (unit-tested)

    nonisolated static func remaining(endDate: Date?, now: Date) -> TimeInterval {
        guard let endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(now))
    }

    /// Formats seconds as M:SS, rounding up so "1s left" shows as 0:01, not 0:00.
    nonisolated static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
