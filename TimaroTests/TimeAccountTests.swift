import XCTest
import SwiftData
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

final class VacationTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private let target: TimeInterval = 8 * 3600
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private func day(_ month: Int, _ day: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func work(_ month: Int, _ d: Int, hours: Double) -> TimeAccount.Entry {
        TimeAccount.Entry(start: day(month, d).addingTimeInterval(8 * hour), worked: hours * hour, isOpen: false)
    }

    func testFullVacationDayDoesNotCostTheAccount() {
        let balance = TimeAccount.balance([], target: target, vacation: [day(10, 26): 1], calendar: calendar)
        XCTAssertEqual(balance, 0, accuracy: 1)
        let days = TimeAccount.days([], target: target, vacation: [day(10, 26): 1], calendar: calendar)
        XCTAssertEqual(days.first?.vacation, 1)
    }

    func testHalfVacationDayHalvesTheTarget() {
        // 4 h worked + half a day off = target met.
        let balance = TimeAccount.balance([work(10, 26, hours: 4)], target: target,
                                          vacation: [day(10, 26): 0.5], calendar: calendar)
        XCTAssertEqual(balance, 0, accuracy: 1)
        // 5 h worked + half a day off = +1 h.
        let more = TimeAccount.balance([work(10, 26, hours: 5)], target: target,
                                       vacation: [day(10, 26): 0.5], calendar: calendar)
        XCTAssertEqual(more, 1 * hour, accuracy: 1)
    }

    func testWorkOnFullVacationDayIsAllOvertime() {
        let balance = TimeAccount.balance([work(10, 26, hours: 2)], target: target,
                                          vacation: [day(10, 26): 1], calendar: calendar)
        XCTAssertEqual(balance, 2 * hour, accuracy: 1)
    }

    func testSummarySplitsTakenAndPlanned() {
        let entries = [
            VacationLedger.Entry(date: day(3, 2), amount: 1),
            VacationLedger.Entry(date: day(3, 3), amount: 0.5),
            VacationLedger.Entry(date: day(12, 22), amount: 1),
            VacationLedger.Entry(date: day(1, 5, year: 2027), amount: 1)
        ]
        let summary = VacationLedger.summary(entries, year: 2026, allowance: 30,
                                             today: day(10, 28), calendar: calendar)
        XCTAssertEqual(summary.taken, 1.5)
        XCTAssertEqual(summary.planned, 1)
        XCTAssertEqual(summary.remaining, 27.5)
    }

    func testRangeSkipsWeekends() {
        // Fri 23 Oct – Tue 27 Oct 2026 → Fri, Mon, Tue.
        let days = VacationLedger.days(from: day(10, 23), to: day(10, 27), skipWeekends: true, calendar: calendar)
        XCTAssertEqual(days, [day(10, 23), day(10, 26), day(10, 27)])
        let all = VacationLedger.days(from: day(10, 23), to: day(10, 27), skipWeekends: false, calendar: calendar)
        XCTAssertEqual(all.count, 5)
    }
}

final class WidgetSnapshotTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func snapshot(pausedAt: Date? = nil, closedBreak: TimeInterval = 0, closedToday: TimeInterval = 0) -> WidgetSnapshot {
        WidgetSnapshot(day: Calendar.current.startOfDay(for: start), sessionStart: start, pausedAt: pausedAt,
                       closedBreakSeconds: closedBreak, todayClosedSeconds: closedToday,
                       todayTarget: 8 * 3600, balance: 0, vacationRemaining: 0, workplaceName: nil)
    }

    func testRunningShiftCountsUpWithoutBreaks() {
        let s = snapshot(closedBreak: 30 * 60, closedToday: 3600)
        let now = start.addingTimeInterval(3 * 3600)
        XCTAssertEqual(s.sessionWorked(at: now), 2.5 * 3600, accuracy: 1)
        XCTAssertEqual(s.todayWorked(at: now), 3.5 * 3600, accuracy: 1)
        // The timer reference makes Text(.timer) show today's worked time.
        let timerStart = try! XCTUnwrap(s.todayTimerStart(at: now))
        XCTAssertEqual(now.timeIntervalSince(timerStart), 3.5 * 3600, accuracy: 1)
        XCTAssertEqual(s.targetReachedAt(now: now)!.timeIntervalSince(now), 4.5 * 3600, accuracy: 1)
    }

    func testBreakStopsTheClock() {
        let s = snapshot(pausedAt: start.addingTimeInterval(2 * 3600))
        let later = start.addingTimeInterval(5 * 3600)
        XCTAssertEqual(s.sessionWorked(at: later), 2 * 3600, accuracy: 1)
        XCTAssertNil(s.todayTimerStart(at: later))
        XCTAssertTrue(s.isPaused)
    }

    func testRoundTripThroughJSON() throws {
        let s = snapshot(closedBreak: 900)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(decoded, s)
    }
}

final class PeriodsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()

    private func day(_ month: Int, _ day: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testMonthsAcrossYearEnd() {
        let months = Periods.months(from: day(11, 15), through: day(2, 3, year: 2027), calendar: calendar)
        XCTAssertEqual(months, [day(11, 1), day(12, 1), day(1, 1, year: 2027), day(2, 1, year: 2027)])
    }

    func testWeeksOfOctober2026StartOnMonday() {
        // 1 Oct 2026 is a Thursday, 31 Oct a Saturday.
        let weeks = Periods.weeks(inMonth: day(10, 1), calendar: calendar)
        XCTAssertEqual(weeks.first, day(9, 28))
        XCTAssertEqual(weeks.last, day(10, 26))
        XCTAssertEqual(weeks.count, 5)
    }

    func testWeekHasSevenConsecutiveDays() {
        let days = Periods.days(ofWeek: day(10, 26), calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first, day(10, 26))
        XCTAssertEqual(days.last, day(11, 1))
    }
}

final class CSVImporterTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private let sample = """
    export_zeiten_2026;;;;;
    Datum;Stunden;Sollstunden;Überstunden;Pause;Abwesenheitstyp
    01.01.26;08:00;08:00;00:00;00:00;FEIERTAG
    02.01.26;08:00;08:00;00:00;00:00;FERIE
    07.01.26;08:10;08:00;00:10;00:45;
    08.01.26;07:30;08:00;-00:30;00:40;
    09.01.26;08:00;08:00;00:00;00:00;
    12.01.26;08:20;08:00;00:20;00:00;FERIE 1/2
    13.01.26;08:00;08:00;00:00;00:00;Sonderurlaub
    30.12.26;00:00;08:00;-08:00;00:00;
    ;1.726:39;2.088:00;-361:21;104:58;
    """

    func testParsesWorkDaysAndSkipsAbsences() {
        let parsed = CSVImporter.parse(sample, calendar: calendar)
        XCTAssertEqual(parsed.days.count, 4)
        XCTAssertEqual(parsed.skippedAbsences, 3)
        XCTAssertEqual(parsed.skippedEmpty, 1)
        let first = parsed.days[0]
        XCTAssertEqual(first.date, calendar.date(from: DateComponents(year: 2026, month: 1, day: 7)))
        XCTAssertEqual(first.worked, (8 * 60 + 10) * 60)
        XCTAssertEqual(first.breakMinutes, 45)
    }

    func testImportedDaysReproduceSourceOvertime() {
        // +0:10 −0:30 ±0 +0:20 = 0:00, the same as the source's overtime column.
        let parsed = CSVImporter.parse(sample, calendar: calendar)
        let entries = parsed.days.map { TimeAccount.Entry(start: $0.date, worked: $0.worked, isOpen: false) }
        XCTAssertEqual(TimeAccount.balance(entries, target: 8 * 3600, calendar: calendar), 0, accuracy: 1)
    }

    func testDurationsAndDates() {
        XCTAssertEqual(CSVImporter.parseMinutes("08:05"), 485)
        XCTAssertEqual(CSVImporter.parseMinutes("-00:45"), -45)
        XCTAssertEqual(CSVImporter.parseMinutes("1.726:39"), 103_599)
        XCTAssertNil(CSVImporter.parseMinutes("FERIE"))
        XCTAssertEqual(CSVImporter.parseDate("07.01.2026", calendar: calendar),
                       calendar.date(from: DateComponents(year: 2026, month: 1, day: 7)))
        XCTAssertNil(CSVImporter.parseDate("", calendar: calendar))
    }
}

@MainActor
final class DeletionTests: XCTestCase {
    func testDeleteByIdentifierRemovesAndPersists() throws {
        let container = try ModelContainer(for: Workplace.self, WorkSession.self, VacationDay.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let keep = VacationDay(date: Date(timeIntervalSinceReferenceDate: 800_000_000))
        let remove = VacationDay(date: Date(timeIntervalSinceReferenceDate: 800_100_000), isHalfDay: true)
        context.insert(keep)
        context.insert(remove)
        try context.save()

        context.deleteAndSave([remove.persistentModelID])

        // A fresh context sees the saved state, not just the in-memory one.
        let fresh = ModelContext(container)
        let remaining = try fresh.fetch(FetchDescriptor<VacationDay>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.isHalfDay, false)
    }
}

final class AbsenceTests: XCTestCase {
    private let day = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testOnlyVacationCountsAgainstTheAllowance() {
        let days = [
            VacationDay(date: day),
            VacationDay(date: day.addingTimeInterval(86_400), reason: "Sick leave"),
            VacationDay(date: day.addingTimeInterval(2 * 86_400), isHalfDay: true)
        ]
        XCTAssertEqual(days.vacationLedgerEntries.map(\.amount), [1, 0.5])
        // Every day off still lowers that day's target.
        XCTAssertEqual(days.byDay.values.reduce(0, +), 2.5)
    }

    func testInfoSplitsVacationAndAbsence() {
        let start = Calendar.current.startOfDay(for: day)
        let info = [VacationDay(date: day, isHalfDay: true),
                    VacationDay(date: day, isHalfDay: true, reason: "Sick leave")].infoByDay[start]
        XCTAssertEqual(info?.vacation, 0.5)
        XCTAssertEqual(info?.absence, 0.5)
        XCTAssertEqual(info?.total, 1)
        XCTAssertEqual(info?.reasons, ["Sick leave"])
    }
}

final class StatisticsTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        calendar.firstWeekday = 2
        return calendar
    }()

    private func day(_ d: Int, month: Int = 11) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: d))!
    }

    private func shift(_ d: Int, hours: Double, month: Int = 11, workplace: String? = "Office",
                       open: Bool = false) -> Statistics.Shift {
        Statistics.Shift(start: day(d, month: month).addingTimeInterval(8 * hour), worked: hours * hour,
                         breaks: 0.5 * hour, earned: hours * 20, workplace: workplace, isOpen: open)
    }

    private var november: DateInterval { calendar.dateInterval(of: .month, for: day(10))! }

    func testTotalsAndOvertimeForTheMonth() {
        let shifts = [shift(2, hours: 9), shift(3, hours: 7), shift(3, hours: 1, workplace: "Client"),
                      shift(30, hours: 8, month: 10)]
        let report = Statistics.report(shifts: shifts, daysOff: [], in: november, dailyTarget: 8 * hour,
                                       grouping: .day, calendar: calendar)
        XCTAssertEqual(report.shifts, 3)
        XCTAssertEqual(report.workDays, 2)
        XCTAssertEqual(report.worked, 17 * hour, accuracy: 1)
        XCTAssertEqual(report.delta, 1 * hour, accuracy: 1)
        XCTAssertEqual(report.breaks, 1.5 * hour, accuracy: 1)
        XCTAssertEqual(report.earned, 340, accuracy: 0.01)
        XCTAssertEqual(report.averagePerWorkDay, 8.5 * hour, accuracy: 1)
        XCTAssertEqual(report.workplaces.map(\.name), ["Office", "Client"])
    }

    func testDaysOffLowerTheTargetAndAreCountedByReason() {
        let off = [Statistics.DayOff(date: day(4), amount: 0.5, reason: ""),
                   Statistics.DayOff(date: day(5), amount: 1, reason: "Sick leave"),
                   Statistics.DayOff(date: day(6), amount: 1, reason: "")]
        let report = Statistics.report(shifts: [shift(4, hours: 4)], daysOff: off, in: november,
                                       dailyTarget: 8 * hour, grouping: .day, calendar: calendar)
        XCTAssertEqual(report.delta, 0, accuracy: 1)
        XCTAssertEqual(report.vacation, 1.5)
        XCTAssertEqual(report.absences, ["Sick leave": 1])
    }

    func testRunningShiftCountsAsWorkedButNotAsOvertime() {
        let report = Statistics.report(shifts: [shift(2, hours: 10, open: true)], daysOff: [], in: november,
                                       dailyTarget: 8 * hour, grouping: .day, calendar: calendar)
        XCTAssertEqual(report.worked, 10 * hour, accuracy: 1)
        XCTAssertEqual(report.delta, 0)
        XCTAssertEqual(report.target, 0)
    }

    func testGroupsCoverTheWholePeriod() {
        let days = Statistics.report(shifts: [shift(2, hours: 8)], daysOff: [], in: november,
                                     dailyTarget: 8 * hour, grouping: .day, calendar: calendar)
        XCTAssertEqual(days.groups.count, 30)
        XCTAssertEqual(days.groups.first?.start, day(1))
        XCTAssertEqual(days.groups[1].worked, 8 * hour, accuracy: 1)

        let year = calendar.dateInterval(of: .year, for: day(10))!
        let months = Statistics.report(shifts: [shift(2, hours: 8), shift(30, hours: 6, month: 10)], daysOff: [],
                                       in: year, dailyTarget: 8 * hour, grouping: .month, calendar: calendar)
        XCTAssertEqual(months.groups.count, 12)
        XCTAssertEqual(months.groups[9].worked, 6 * hour, accuracy: 1)
        XCTAssertEqual(months.groups[10].worked, 8 * hour, accuracy: 1)
    }

    func testWeekdayAveragesStartOnMonday() {
        // Mon 2 and Mon 9 Nov 2026, Wed 4 Nov.
        let shifts = [shift(2, hours: 8), shift(9, hours: 6), shift(4, hours: 9)]
        let report = Statistics.report(shifts: shifts, daysOff: [], in: november, dailyTarget: 8 * hour,
                                       grouping: .day, calendar: calendar)
        XCTAssertEqual(report.weekdays.map(\.weekday), [2, 4])
        XCTAssertEqual(report.weekdays.first?.average ?? 0, 7 * hour, accuracy: 1)
    }

    func testGroupingDependsOnPeriodLength() {
        let week = calendar.dateInterval(of: .weekOfYear, for: day(10))!
        XCTAssertEqual(Statistics.grouping(for: week), .day)
        XCTAssertEqual(Statistics.grouping(for: november), .day)
        let quarter = DateInterval(start: day(1, month: 9), end: day(1, month: 12))
        XCTAssertEqual(Statistics.grouping(for: quarter), .week)
        XCTAssertEqual(Statistics.grouping(for: calendar.dateInterval(of: .year, for: day(10))!), .month)
    }
}

final class StatisticsTagTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func shift(hours: Double, tags: [String]) -> Statistics.Shift {
        Statistics.Shift(start: start, worked: hours * 3600, breaks: 0, earned: 0,
                         workplace: nil, isOpen: false, tags: tags)
    }

    func testHoursPerTagCountShiftsForEachOfTheirTags() {
        let shifts = [shift(hours: 8, tags: ["Home office"]),
                      shift(hours: 2, tags: ["Home office", "Training"]),
                      shift(hours: 3, tags: [])]
        let report = Statistics.report(shifts: shifts, daysOff: [],
                                       in: DateInterval(start: start.addingTimeInterval(-3600), duration: 86_400),
                                       dailyTarget: 8 * 3600, grouping: .day)
        XCTAssertEqual(report.tags.map(\.name), ["Home office", "", "Training"])
        XCTAssertEqual(report.tags.map(\.worked), [10 * 3600, 3 * 3600, 2 * 3600])
        XCTAssertEqual(report.worked, 13 * 3600, accuracy: 1)
    }
}
