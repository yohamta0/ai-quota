import XCTest
@testable import AIQuotaKit

final class DailyPaceTextFormatterTests: XCTestCase {
    func testUnspentBudgetReadsAsRemaining() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(startUtilization: 55, allowance: 11.25, spent: 4)
        )
        XCTAssertEqual(text, "7.3% left")
    }

    func testOverspentBudgetReadsAsOverage() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(startUtilization: 55, allowance: 11.25, spent: 15)
        )
        XCTAssertEqual(text, "3.8% over")
    }

    func testFullySpentBudgetIsNotReportedAsOverage() {
        let text = DailyPaceTextFormatter.remainingText(
            for: DailyPaceBudget(startUtilization: 55, allowance: 11.25, spent: 11.25)
        )
        XCTAssertEqual(text, "0.0% left")
    }
}
