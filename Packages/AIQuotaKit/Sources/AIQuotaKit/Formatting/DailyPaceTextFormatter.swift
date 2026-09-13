import Foundation

public enum DailyPaceTextFormatter {
    /// Renders what is left of today's share, or by how much it has been exceeded.
    public static func remainingText(for budget: DailyPaceBudget) -> String {
        let remaining = budget.remaining
        // Half away from zero, matching how utilization is rounded elsewhere.
        let magnitude = String(format: "%.1f", (abs(remaining) * 10).rounded() / 10)

        return remaining < 0 ? "\(magnitude)% over" : "\(magnitude)% left"
    }
}
