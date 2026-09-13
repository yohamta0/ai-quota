import XCTest
@testable import AIQuotaKit

final class DailyPacePolicyTests: XCTestCase {
    func testMidnightAlignedWindowGivesTheFirstDayOneSeventh() {
        let budget = budget(
            utilization: 0,
            resetAt: Self.midnight.addingTimeInterval(Self.week),
            now: Self.midnight.addingTimeInterval(10 * 3_600)
        )
        XCTAssertEqual(budget?.ceiling ?? 0, 100.0 / 7.0, accuracy: 0.01)
    }

    func testCeilingIsMeasuredFromTheRealWindowStartNotMidnight() {
        // The window runs Sat 04:00 → Sat 04:00, so by the end of Sunday
        // 1.83 of its 7 days are gone — not the 2 a midnight split would imply.
        XCTAssertEqual(claudeBudget(utilization: 37)?.ceiling ?? 0, 26.19, accuracy: 0.01)
    }

    func testUsagePastTheCeilingIsReportedAsOverage() {
        let budget = claudeBudget(utilization: 37)
        XCTAssertEqual(budget?.headroom ?? 0, -10.81, accuracy: 0.01)
        XCTAssertTrue(budget?.isOver ?? false)
    }

    func testUsageUnderTheCeilingLeavesHeadroom() {
        let budget = claudeBudget(utilization: 20)
        XCTAssertEqual(budget?.headroom ?? 0, 6.19, accuracy: 0.01)
        XCTAssertFalse(budget?.isOver ?? true)
    }

    func testCeilingHoldsStillAcrossTheDay() {
        let morning = budget(
            utilization: 30,
            resetAt: Self.saturdayReset,
            now: Self.sundayNight.addingTimeInterval(-15 * 3_600)
        )
        XCTAssertEqual(morning?.ceiling ?? 0, claudeBudget(utilization: 37)?.ceiling ?? -1, accuracy: 0.001)
    }

    func testCeilingStepsUpByOneDayAfterMidnight() {
        let tomorrow = budget(
            utilization: 37,
            resetAt: Self.saturdayReset,
            now: Self.sundayNight.addingTimeInterval(3 * 3_600)
        )
        let tonight = claudeBudget(utilization: 37)
        XCTAssertEqual((tomorrow?.ceiling ?? 0) - (tonight?.ceiling ?? 0), 100.0 / 7.0, accuracy: 0.01)
    }

    func testFinalDayAllowsTheWholeWindow() {
        let budget = budget(
            utilization: 80,
            resetAt: Self.sundayNight.addingTimeInterval(3_600),
            now: Self.sundayNight
        )
        XCTAssertEqual(budget?.ceiling ?? 0, 100, accuracy: 0.01)
    }

    func testResetAlreadyPassedDisablesPacing() {
        XCTAssertNil(budget(
            utilization: 37,
            resetAt: Self.sundayNight.addingTimeInterval(-3_600),
            now: Self.sundayNight
        ))
    }

    func testDistantFutureResetDisablesPacing() {
        XCTAssertNil(budget(utilization: 37, resetAt: .distantFuture, now: Self.sundayNight))
    }

    // MARK: - Helpers

    private static let week: TimeInterval = 7 * 86_400

    /// 2026-09-14 00:00 JST
    private static let midnight = Date(timeIntervalSince1970: 1_789_311_600)
    /// 2026-09-19 04:00 JST — the reset the live Claude account reported.
    private static let saturdayReset = Date(timeIntervalSince1970: 1_789_758_000)
    /// 2026-09-13 22:18 JST
    private static let sundayNight = Date(timeIntervalSince1970: 1_789_305_480)

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    private func claudeBudget(utilization: Double) -> DailyPaceBudget? {
        budget(utilization: utilization, resetAt: Self.saturdayReset, now: Self.sundayNight)
    }

    private func budget(utilization: Double, resetAt: Date, now: Date) -> DailyPaceBudget? {
        DailyPacePolicy.budget(
            utilization: utilization,
            resetAt: resetAt,
            windowLength: Self.week,
            now: now,
            calendar: Self.calendar
        )
    }
}
