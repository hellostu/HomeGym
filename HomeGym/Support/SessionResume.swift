import Foundation

/// Decides which past session (if any) should be resumed when a workout is started.
/// Pure and free of SwiftData/UI so it can be unit-tested directly.
enum SessionResume {
    /// The most recent session that is neither completed nor skipped and still points
    /// at an exercise — i.e. one you opened but never pressed Done on.
    static func candidate(from sessions: [SnackSession]) -> SnackSession? {
        sessions
            .filter { !$0.completed && !$0.skipped && $0.exercise != nil }
            .sorted { $0.date > $1.date }
            .first
    }
}
