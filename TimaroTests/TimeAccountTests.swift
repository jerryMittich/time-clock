import XCTest
@testable import Timaro

final class TimeAccountTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private let target: TimeInterval = 8 * 3600
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func entry(_ day: Int, worked hours: Double, open: Bool = false) -> TimeAccount.Entry {
        TimeAccount.Entry(start: date(day, 8), worked: hours * hour, isOpen: open)
    }

    func testOvertimeIsCredited() {
        let balance = TimeAccount.balance([entry(26, worked: 9.5)], target: target, calendar: calendar)
        XCTAssertEqual(balance, 1.5 * hour, accuracy: 1)
    }

    func testShortDayIsCoveredFromAccount() {
        // +2h on Monday, −1h on Tuesday → +1h left.
        let entries = [entry(26, worked: 10), entry(27, worked: 7)]
        XCTAssertEqual(TimeAccount.balance(entries, target: target, calendar: calendar), 1 * hour, accuracy: 1)
    }

    func testBalanceCanGoNegative() {
        let entries = [entry(26, worked: 6)]
        XCTAssertEqual(TimeAccount.balance(entries, target: target, calendar: calendar), -2 * hour, accuracy: 1)
    }

    func testSeveralShiftsOnOneDayAreSummed() {
        let entries = [entry(26, worked: 4), entry(26, worked: 5)]
        let days = TimeAccount.days(entries, target: target, calendar: calendar)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[0].worked, 9 * hour, accuracy: 1)
        XCTAssertEqual(days[0].delta, 1 * hour, accuracy: 1)
    }

    func testDaysWithoutShiftsAreNotCounted() {
        // Friday and Monday with a weekend in between: the weekend does not cost anything.
        let entries = [entry(23, worked: 8), entry(26, worked: 8)]
        XCTAssertEqual(TimeAccount.balance(entries, target: target, calendar: calendar), 0, accuracy: 1)
    }

    func testRunningDayIsNotBookedYet() {
        let entries = [entry(26, worked: 9), entry(27, worked: 3, open: true)]
        XCTAssertEqual(TimeAccount.balance(entries, target: target, calendar: calendar), 1 * hour, accuracy: 1)
        let today = TimeAccount.days(entries, target: target, calendar: calendar).first
        XCTAssertEqual(today?.inProgress, true)
    }

    func testStartingBalanceIsIncluded() {
        let balance = TimeAccount.balance([entry(26, worked: 7)], target: target,
                                          initial: 5 * hour, calendar: calendar)
        XCTAssertEqual(balance, 4 * hour, accuracy: 1)
    }
}

final class WorkSessionBreakTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    func testBreakIsExcludedFromWorkedTime() {
        let session = WorkSession(start: start)
        session.startBreak(at: start.addingTimeInterval(4 * 3600))
        session.endBreak(at: start.addingTimeInterval(4.5 * 3600))
        session.close(at: start.addingTimeInterval(9 * 3600))
        XCTAssertEqual(session.breakMinutes, 30)
        XCTAssertEqual(session.duration(), 8.5 * 3600, accuracy: 1)
    }

    func testClockStopsDuringBreak() {
        let session = WorkSession(start: start)
        session.startBreak(at: start.addingTimeInterval(3600))
        let during = session.duration(now: start.addingTimeInterval(1.5 * 3600))
        XCTAssertEqual(during, 3600, accuracy: 1)
        XCTAssertTrue(session.isPaused)
    }

    func testFinishingDuringBreakClosesTheBreak() {
        let session = WorkSession(start: start)
        session.startBreak(at: start.addingTimeInterval(7 * 3600))
        session.close(at: start.addingTimeInterval(7.25 * 3600))
        XCTAssertNil(session.pausedAt)
        XCTAssertEqual(session.breakMinutes, 15)
        XCTAssertEqual(session.duration(), 7 * 3600, accuracy: 1)
    }

    func testMultipleBreaksAccumulate() {
        let session = WorkSession(start: start)
        session.startBreak(at: start.addingTimeInterval(2 * 3600))
        session.endBreak(at: start.addingTimeInterval(2 * 3600 + 15 * 60))
        session.startBreak(at: start.addingTimeInterval(5 * 3600))
        session.endBreak(at: start.addingTimeInterval(5 * 3600 + 30 * 60))
        XCTAssertEqual(session.breakMinutes, 45)
    }
}
