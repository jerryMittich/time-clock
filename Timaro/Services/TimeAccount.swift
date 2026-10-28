import Foundation

/// Daily target bookkeeping ("Stundenkonto"). Every finished working day adds its
/// difference to the daily target: time above the target is credited, time below it is
/// taken from the account. Days without any shift are not counted (weekends, holidays).
enum TimeAccount {
    struct Entry {
        var start: Date
        var worked: TimeInterval
        var isOpen: Bool
    }

    struct Day: Identifiable {
        var date: Date
        var worked: TimeInterval
        /// worked − target
        var delta: TimeInterval
        /// A shift on this day is still running, so the day is not booked yet.
        var inProgress: Bool
        var id: Date { date }
    }

    /// One entry per calendar day that has at least one shift, newest first.
    /// Shifts are assigned to the day they started on.
    static func days(_ entries: [Entry], target: TimeInterval, calendar: Calendar = .current) -> [Day] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.start) }
        return grouped.map { date, entries in
            let worked = entries.reduce(0) { $0 + $1.worked }
            return Day(date: date,
                       worked: worked,
                       delta: worked - target,
                       inProgress: entries.contains(where: \.isOpen))
        }
        .sorted { $0.date > $1.date }
    }

    /// Account balance in seconds from all booked (finished) days plus the starting balance.
    static func balance(_ entries: [Entry],
                        target: TimeInterval,
                        initial: TimeInterval = 0,
                        calendar: Calendar = .current) -> TimeInterval {
        days(entries, target: target, calendar: calendar)
            .filter { !$0.inProgress }
            .reduce(initial) { $0 + $1.delta }
    }
}

extension WorkSession {
    func accountEntry(now: Date = .now) -> TimeAccount.Entry {
        TimeAccount.Entry(start: start, worked: duration(now: now), isOpen: isOpen)
    }
}
