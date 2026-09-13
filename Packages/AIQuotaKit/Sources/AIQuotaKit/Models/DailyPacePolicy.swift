import Foundation

/// How far into a quota window today is allowed to reach, against how far it
/// actually has.
public struct DailyPaceBudget: Sendable, Equatable {
    /// Utilization today may reach without outrunning the window.
    public let ceiling: Double
    public let utilization: Double

    /// Quota still available before today's ceiling; negative once past it.
    public var headroom: Double { ceiling - utilization }
    public var isOver: Bool { headroom < 0 }

    public init(ceiling: Double, utilization: Double) {
        self.ceiling = ceiling
        self.utilization = utilization
    }
}

/// Paces a quota window by spending it evenly over its own length.
///
/// The ceiling is the share of the window elapsed by the end of today, so it is
/// anchored to when the window actually opened — not to midnight, which the
/// window boundary rarely lines up with. It holds still all day and steps up
/// once at local midnight.
public enum DailyPacePolicy {
    public static func budget(
        utilization: Double,
        resetAt: Date,
        windowLength: TimeInterval,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DailyPaceBudget? {
        guard resetAt != .distantFuture, resetAt != .distantPast, resetAt > now, windowLength > 0 else {
            return nil
        }

        let windowStart = resetAt.addingTimeInterval(-windowLength)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let elapsed = min(endOfToday, resetAt).timeIntervalSince(windowStart)

        return DailyPaceBudget(
            ceiling: min(100, max(0, 100 * elapsed / windowLength)),
            utilization: utilization
        )
    }
}
