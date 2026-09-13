import Foundation

public enum DailyPaceTextFormatter {
    /// Renders the room left before today's ceiling, or how far past it usage is.
    public static func remainingText(for budget: DailyPaceBudget) -> String {
        let headroom = budget.headroom
        // Half away from zero, matching how utilization is rounded elsewhere.
        let magnitude = String(format: "%.1f", (abs(headroom) * 10).rounded() / 10)

        return headroom < 0 ? "\(magnitude)% over" : "\(magnitude)% left"
    }
}
