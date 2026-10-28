import Foundation

/// Month and week helpers for the timesheet pages and the weekly chart.
enum Periods {
    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func startOfWeek(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// Month starts from the month of `first` through the month of `last`, oldest first.
    static func months(from first: Date, through last: Date, calendar: Calendar = .current) -> [Date] {
        var month = startOfMonth(min(first, last), calendar: calendar)
        let end = startOfMonth(max(first, last), calendar: calendar)
        var result: [Date] = []
        while month <= end {
            result.append(month)
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return result
    }

    /// The seven days of the week that starts at `weekStart`.
    static func days(ofWeek weekStart: Date, calendar: Calendar = .current) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Starts of all weeks that overlap the month, oldest first.
    static func weeks(inMonth monthStart: Date, calendar: Calendar = .current) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { return [] }
        var week = startOfWeek(interval.start, calendar: calendar)
        var result: [Date] = []
        while week < interval.end {
            result.append(week)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: week) else { break }
            week = next
        }
        return result
    }
}
