import Foundation

/// Yearly vacation bookkeeping: allowance, days already taken, days planned, days left.
enum VacationLedger {
    struct Entry {
        var date: Date
        var amount: Double
    }

    struct Summary: Equatable {
        var allowance: Double
        /// Vacation on or before today.
        var taken: Double
        /// Vacation after today.
        var planned: Double
        var remaining: Double { allowance - taken - planned }
    }

    static func summary(_ entries: [Entry],
                        year: Int,
                        allowance: Double,
                        today: Date = .now,
                        calendar: Calendar = .current) -> Summary {
        let todayStart = calendar.startOfDay(for: today)
        var summary = Summary(allowance: allowance, taken: 0, planned: 0)
        for entry in entries where calendar.component(.year, from: entry.date) == year {
            if calendar.startOfDay(for: entry.date) <= todayStart {
                summary.taken += entry.amount
            } else {
                summary.planned += entry.amount
            }
        }
        return summary
    }

    /// The days from `start` through `end` (inclusive), optionally without Saturdays and Sundays.
    static func days(from start: Date,
                     to end: Date,
                     skipWeekends: Bool,
                     calendar: Calendar = .current) -> [Date] {
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: max(start, end))
        var result: [Date] = []
        while day <= last {
            if !(skipWeekends && calendar.isDateInWeekend(day)) {
                result.append(day)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}

extension VacationDay {
    var ledgerEntry: VacationLedger.Entry { .init(date: date, amount: amount) }
}
