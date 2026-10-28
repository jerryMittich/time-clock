import Foundation

/// Daily target bookkeeping ("Stundenkonto"). Every finished working day adds its
/// difference to the daily target: time above the target is credited, time below it is
/// taken from the account. Days without any shift are not counted (weekends, holidays).
/// Vacation lowers that day's target: a half day off halves it, a full day off clears it.
enum TimeAccount {
    struct Entry {
        var start: Date
        var worked: TimeInterval
        var isOpen: Bool
    }

    struct Day: Identifiable {
        var date: Date
        var worked: TimeInterval
        /// Vacation taken on this day: 0, 0.5 or 1.
        var vacation: Double
        /// worked − target for this day; 0 for days without shifts.
        var delta: TimeInterval
        /// A shift on this day is still running, so the day is not booked yet.
        var inProgress: Bool
        var hasShifts: Bool
        var id: Date { date }
    }

    /// The target for one day after subtracting vacation.
    static func target(_ target: TimeInterval, vacation: Double) -> TimeInterval {
        target * max(0, 1 - vacation)
    }

    /// One entry per calendar day that has a shift or vacation, newest first.
    /// Shifts are assigned to the day they started on. `vacation` maps start-of-day to 0.5 or 1.
    static func days(_ entries: [Entry],
                     target: TimeInterval,
                     vacation: [Date: Double] = [:],
                     calendar: Calendar = .current) -> [Day] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.start) }
        let vacationByDay = Dictionary(vacation.map { (calendar.startOfDay(for: $0.key), $0.value) },
                                       uniquingKeysWith: +)
        let dates = Set(grouped.keys).union(vacationByDay.keys)
        return dates.map { date in
            let shifts = grouped[date] ?? []
            let worked = shifts.reduce(0) { $0 + $1.worked }
            let off = min(1, vacationByDay[date] ?? 0)
            return Day(date: date,
                       worked: worked,
                       vacation: off,
                       delta: shifts.isEmpty ? 0 : worked - Self.target(target, vacation: off),
                       inProgress: shifts.contains(where: \.isOpen),
                       hasShifts: !shifts.isEmpty)
        }
        .sorted { $0.date > $1.date }
    }

    /// Account balance in seconds from all booked (finished) days plus the starting balance.
    static func balance(_ entries: [Entry],
                        target: TimeInterval,
                        vacation: [Date: Double] = [:],
                        initial: TimeInterval = 0,
                        calendar: Calendar = .current) -> TimeInterval {
        days(entries, target: target, vacation: vacation, calendar: calendar)
            .filter { !$0.inProgress }
            .reduce(initial) { $0 + $1.delta }
    }
}

extension WorkSession {
    func accountEntry(now: Date = .now) -> TimeAccount.Entry {
        TimeAccount.Entry(start: start, worked: duration(now: now), isOpen: isOpen)
    }
}
