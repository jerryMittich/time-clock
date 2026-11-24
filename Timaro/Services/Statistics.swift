import Foundation

/// Figures for the statistics tab: totals, hours per day/week/month, average per weekday,
/// share per workplace and per tag, and days off, for one period. Target and overtime follow the
/// time account (`TimeAccount`): only days with shifts count, days off lower the target.
enum Statistics {
    struct Shift {
        var start: Date
        var worked: TimeInterval
        var breaks: TimeInterval
        var earned: Double
        var workplace: String?
        var isOpen: Bool
        var tags: [String] = []
    }

    struct DayOff {
        var date: Date
        var amount: Double
        /// Empty for vacation, else the absence reason.
        var reason: String
    }

    enum Grouping {
        case day, week, month

        var component: Calendar.Component {
            switch self {
            case .day: .day
            case .week: .weekOfYear
            case .month: .month
            }
        }
    }

    struct Group: Identifiable, Equatable {
        var start: Date
        var worked: TimeInterval = 0
        var delta: TimeInterval = 0
        var earned: Double = 0
        var workDays = 0
        var id: Date { start }
    }

    struct WeekdayAverage: Identifiable, Equatable {
        /// Calendar weekday, 1 = Sunday.
        var weekday: Int
        var average: TimeInterval
        var id: Int { weekday }
    }

    struct Share: Identifiable, Equatable {
        /// Workplace or tag; empty for shifts without one.
        var name: String
        var worked: TimeInterval
        var id: String { name }
    }

    struct Report {
        var worked: TimeInterval = 0
        /// Target of the booked (finished) working days.
        var target: TimeInterval = 0
        var delta: TimeInterval = 0
        var breaks: TimeInterval = 0
        var earned: Double = 0
        var shifts = 0
        var workDays = 0
        var vacation: Double = 0
        /// Absence reason → days.
        var absences: [String: Double] = [:]
        /// Every day, week or month of the period, oldest first, including empty ones.
        var groups: [Group] = []
        /// In calendar order, starting with the first weekday; only weekdays that were worked.
        var weekdays: [WeekdayAverage] = []
        /// Largest first.
        var workplaces: [Share] = []
        /// Largest first. A shift with several tags counts for each of them.
        var tags: [Share] = []

        var averagePerWorkDay: TimeInterval { workDays > 0 ? worked / Double(workDays) : 0 }
        var absenceDays: Double { absences.values.reduce(0, +) }
        var isEmpty: Bool { shifts == 0 && vacation == 0 && absences.isEmpty }
    }

    /// Days for short periods, weeks up to about half a year, months beyond.
    static func grouping(for interval: DateInterval) -> Grouping {
        let days = interval.duration / 86_400
        return days <= 31.5 ? .day : (days <= 190 ? .week : .month)
    }

    static func report(shifts: [Shift],
                       daysOff: [DayOff],
                       in interval: DateInterval,
                       dailyTarget: TimeInterval,
                       grouping: Grouping,
                       calendar: Calendar = .current) -> Report {
        let inRange = shifts.filter { $0.start >= interval.start && $0.start < interval.end }
        let offInRange = daysOff.filter { $0.date >= interval.start && $0.date < interval.end }
        var report = Report()

        report.shifts = inRange.count
        report.worked = inRange.reduce(0) { $0 + $1.worked }
        report.breaks = inRange.reduce(0) { $0 + $1.breaks }
        report.earned = inRange.reduce(0) { $0 + $1.earned }

        for off in offInRange {
            if off.reason.isEmpty {
                report.vacation += off.amount
            } else {
                report.absences[off.reason, default: 0] += off.amount
            }
        }

        let offByDay = Dictionary(offInRange.map { (calendar.startOfDay(for: $0.date), $0.amount) },
                                  uniquingKeysWith: +)
        let workDays = TimeAccount.days(inRange.map { TimeAccount.Entry(start: $0.start, worked: $0.worked, isOpen: $0.isOpen) },
                                        target: dailyTarget,
                                        vacation: offByDay,
                                        calendar: calendar)
            .filter(\.hasShifts)
        report.workDays = workDays.count
        for day in workDays where !day.inProgress {
            report.target += TimeAccount.target(dailyTarget, vacation: day.vacation)
            report.delta += day.delta
        }

        // Groups: every period step in the interval, so the chart has no gaps.
        func groupStart(_ date: Date) -> Date {
            calendar.dateInterval(of: grouping.component, for: date)?.start ?? calendar.startOfDay(for: date)
        }
        var groups: [Date: Group] = [:]
        var step = groupStart(interval.start)
        while step < interval.end {
            groups[step] = Group(start: step)
            guard let next = calendar.date(byAdding: grouping.component, value: 1, to: step), next > step else { break }
            step = next
        }
        for day in workDays {
            let key = groupStart(day.date)
            var group = groups[key] ?? Group(start: key)
            group.worked += day.worked
            group.workDays += 1
            if !day.inProgress { group.delta += day.delta }
            groups[key] = group
        }
        for shift in inRange {
            groups[groupStart(shift.start), default: Group(start: groupStart(shift.start))].earned += shift.earned
        }
        report.groups = groups.values.sorted { $0.start < $1.start }

        // Average per weekday over the days that were worked.
        let byWeekday = Dictionary(grouping: workDays) { calendar.component(.weekday, from: $0.date) }
        report.weekdays = (0..<7)
            .map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
            .compactMap { weekday in
                guard let days = byWeekday[weekday], !days.isEmpty else { return nil }
                return WeekdayAverage(weekday: weekday,
                                      average: days.reduce(0) { $0 + $1.worked } / Double(days.count))
            }

        report.workplaces = Dictionary(grouping: inRange) { $0.workplace ?? "" }
            .map { Share(name: $0.key, worked: $0.value.reduce(0) { $0 + $1.worked }) }
            .filter { $0.worked > 0 }
            .sorted { $0.worked > $1.worked }

        var byTag: [String: TimeInterval] = [:]
        for shift in inRange {
            for tag in shift.tags.isEmpty ? [""] : shift.tags {
                byTag[tag, default: 0] += shift.worked
            }
        }
        report.tags = byTag
            .map { Share(name: $0.key, worked: $0.value) }
            .filter { $0.worked > 0 }
            .sorted { $0.worked > $1.worked }

        return report
    }
}
