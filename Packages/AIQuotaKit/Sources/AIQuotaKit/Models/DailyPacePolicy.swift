import Foundation

/// Today's share of a weekly quota, and how much of that share is already gone.
public struct DailyPaceBudget: Sendable, Equatable {
    public let startUtilization: Double
    public let allowance: Double
    public let spent: Double

    public var remaining: Double { allowance - spent }
    public var isOver: Bool { spent > allowance }

    /// Utilization at which today's share runs out — where a gauge marks the line.
    public var limit: Double { startUtilization + allowance }

    public init(startUtilization: Double, allowance: Double, spent: Double) {
        self.startUtilization = startUtilization
        self.allowance = allowance
        self.spent = spent
    }
}

/// The start-of-day reference a day's share is measured against.
///
/// Persisted between refreshes so the share stays fixed for the whole day instead
/// of drifting downward as quota is consumed.
public struct DailyPaceBaseline: Codable, Sendable, Equatable {
    public let day: Date
    public let utilization: Double
    public let allowance: Double

    public init(day: Date, utilization: Double, allowance: Double) {
        self.day = day
        self.utilization = utilization
        self.allowance = allowance
    }
}

/// Rations a weekly quota into equal daily shares.
///
/// The share is recomputed once per local day from what is left of the quota and
/// how many days remain before it resets. Overspending on one day therefore
/// shrinks every later day rather than carrying the user past the weekly limit.
public enum DailyPacePolicy {
    public struct Outcome: Sendable, Equatable {
        public let budget: DailyPaceBudget
        public let baseline: DailyPaceBaseline

        public init(budget: DailyPaceBudget, baseline: DailyPaceBaseline) {
            self.budget = budget
            self.baseline = baseline
        }
    }

    /// Returns today's budget together with the baseline the caller should persist.
    ///
    /// Returns `nil` when the window reports no usable reset date, where rationing
    /// would have no horizon to divide by.
    public static func evaluate(
        utilization: Double,
        resetAt: Date,
        baseline: DailyPaceBaseline?,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Outcome? {
        guard resetAt != .distantFuture, resetAt != .distantPast, resetAt > now else {
            return nil
        }

        let current = baseline.flatMap {
            carriesOver($0, utilization: utilization, now: now, calendar: calendar) ? $0 : nil
        } ?? makeBaseline(utilization: utilization, resetAt: resetAt, now: now, calendar: calendar)

        return Outcome(
            budget: DailyPaceBudget(
                startUtilization: current.utilization,
                allowance: current.allowance,
                spent: max(0, utilization - current.utilization)
            ),
            baseline: current
        )
    }

    /// A baseline survives until the local day turns over, or until the window
    /// resets — which shows up as utilization dropping below the recorded start.
    private static func carriesOver(
        _ baseline: DailyPaceBaseline,
        utilization: Double,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        calendar.isDate(baseline.day, inSameDayAs: now) && utilization >= baseline.utilization
    }

    private static func makeBaseline(
        utilization: Double,
        resetAt: Date,
        now: Date,
        calendar: Calendar
    ) -> DailyPaceBaseline {
        let remainingQuota = max(0, 100 - utilization)
        let remainingDays = max(1, Int(ceil(resetAt.timeIntervalSince(now) / 86_400)))

        return DailyPaceBaseline(
            day: calendar.startOfDay(for: now),
            utilization: utilization,
            allowance: remainingQuota / Double(remainingDays)
        )
    }
}
