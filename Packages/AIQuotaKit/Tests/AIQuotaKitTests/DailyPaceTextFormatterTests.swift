import XCTest
@testable import AIQuotaKit

final class DailyPaceTextFormatterTests: XCTestCase {
    func testHeadroomBelowTheCeilingReadsAsRemaining() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(ceiling: 26.19, utilization: 20)
        )
        XCTAssertEqual(text, "6.2% left")
    }

    func testUsagePastTheCeilingReadsAsOverage() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(ceiling: 26.19, utilization: 37)
        )
        XCTAssertEqual(text, "10.8% over")
    }

    func testUsageExactlyAtTheCeilingIsNotOverage() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(ceiling: 26.19, utilization: 26.19)
        )
        XCTAssertEqual(text, "0.0% left")
    }
}
