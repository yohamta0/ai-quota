import XCTest
@testable import AIQuotaKit

final class DailyPacePolicyTests: XCTestCase {
    func testResetSevenDaysOutSplitsFullQuotaIntoSevenDays() {
        let outcome = evaluate(utilization: 0, resetInDays: 7)
        XCTAssertEqual(outcome?.budget.allowance ?? 0, 100.0 / 7.0, accuracy: 0.01)
    }

    func testAllowanceDividesRemainingQuotaByRemainingDays() {
        let outcome = evaluate(utilization: 55, resetInDays: 3.5)
        XCTAssertEqual(outcome?.budget.allowance ?? 0, 11.25, accuracy: 0.01)
    }

    func testFinalDayAllowsTheEntireRemainingQuota() {
        let outcome = evaluate(utilization: 80, resetInDays: 0.25)
        XCTAssertEqual(outcome?.budget.allowance ?? 0, 20, accuracy: 0.01)
    }

    func testExhaustedQuotaAllowsNothing() {
        let outcome = evaluate(utilization: 100, resetInDays: 3)
        XCTAssertEqual(outcome?.budget.allowance ?? -1, 0, accuracy: 0.01)
    }

    func testLimitMarksWhereTodaysShareRunsOut() {
        let outcome = evaluate(utilization: 55, resetInDays: 3.5)
        XCTAssertEqual(outcome?.budget.limit ?? 0, 66.25, accuracy: 0.01)
    }

    func testLimitIsUnaffectedBySpendingLaterInTheDay() {
        let morning = evaluate(utilization: 55, resetInDays: 3.5)
        let afternoon = evaluate(
            utilization: 62,
            resetInDays: 3.5,
            baseline: morning?.baseline,
            hoursAfterMidnight: 15
        )
        XCTAssertEqual(afternoon?.budget.limit ?? 0, 66.25, accuracy: 0.01)
    }

    func testRemainingCountsDownAsQuotaIsSpentDuringTheDay() {
        let morning = evaluate(utilization: 55, resetInDays: 3.5)
        let afternoon = evaluate(
            utilization: 59,
            resetInDays: 3.5,
            baseline: morning?.baseline,
            hoursAfterMidnight: 15
        )

        XCTAssertEqual(afternoon?.budget.spent ?? 0, 4, accuracy: 0.01)
        XCTAssertEqual(afternoon?.budget.remaining ?? 0, 7.25, accuracy: 0.01)
        XCTAssertFalse(afternoon?.budget.isOver ?? true)
    }

    func testAllowanceStaysFixedForTheRestOfTheDay() {
        let morning = evaluate(utilization: 55, resetInDays: 3.5)
        let afternoon = evaluate(
            utilization: 59,
            resetInDays: 3.5,
            baseline: morning?.baseline,
            hoursAfterMidnight: 15
        )

        XCTAssertEqual(afternoon?.budget.allowance ?? 0, morning?.budget.allowance ?? -1, accuracy: 0.001)
    }

    func testSpendingPastTodaysAllowanceReportsOverage() {
        let morning = evaluate(utilization: 55, resetInDays: 3.5)
        let evening = evaluate(
            utilization: 70,
            resetInDays: 3.5,
            baseline: morning?.baseline,
            hoursAfterMidnight: 20
        )

        XCTAssertTrue(evening?.budget.isOver ?? false)
        XCTAssertEqual(evening?.budget.remaining ?? 0, -3.75, accuracy: 0.01)
    }

    func testNewLocalDayRebuildsTheBaseline() {
        let yesterday = evaluate(utilization: 55, resetInDays: 3.5)
        let today = evaluate(
            utilization: 62,
            resetInDays: 2.5,
            baseline: yesterday?.baseline,
            daysAfterMidnight: 1
        )

        XCTAssertEqual(today?.budget.spent ?? -1, 0, accuracy: 0.01)
        XCTAssertEqual(today?.budget.allowance ?? 0, 38.0 / 3.0, accuracy: 0.01)
    }

    func testWindowResetRebuildsTheBaseline() {
        let beforeReset = evaluate(utilization: 90, resetInDays: 0.1)
        let afterReset = evaluate(
            utilization: 2,
            resetInDays: 7,
            baseline: beforeReset?.baseline,
            hoursAfterMidnight: 18
        )

        XCTAssertEqual(afterReset?.budget.spent ?? -1, 0, accuracy: 0.01)
        XCTAssertEqual(afterReset?.budget.allowance ?? 0, 98.0 / 7.0, accuracy: 0.01)
    }

    func testResetAlreadyPassedDisablesPacing() {
        XCTAssertNil(evaluate(utilization: 55, resetInDays: -1))
    }

    func testDistantFutureResetDisablesPacing() {
        let outcome = DailyPacePolicy.evaluate(
            utilization: 55,
            resetAt: .distantFuture,
            baseline: nil,
            now: Self.midnight,
            calendar: Self.calendar
        )
        XCTAssertNil(outcome)
    }

    // MARK: - Helpers

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    /// 2026-09-14 00:00 JST — the local midnight every case is anchored to.
    private static let midnight = Date(timeIntervalSince1970: 1_789_311_600)

    private func evaluate(
        utilization: Double,
        resetInDays: Double,
        baseline: DailyPaceBaseline? = nil,
        hoursAfterMidnight: Double = 0,
        daysAfterMidnight: Double = 0
    ) -> DailyPacePolicy.Outcome? {
        let now = Self.midnight
            .addingTimeInterval(daysAfterMidnight * 86_400)
            .addingTimeInterval(hoursAfterMidnight * 3_600)
        return DailyPacePolicy.evaluate(
            utilization: utilization,
            resetAt: now.addingTimeInterval(resetInDays * 86_400),
            baseline: baseline,
            now: now,
            calendar: Self.calendar
        )
    }
}
