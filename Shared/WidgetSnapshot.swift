import Foundation

/// Compact status the app publishes for its widgets through the shared App Group.
/// The widget never opens the database; it only reads this snapshot and computes
/// live values (running timer, today's progress) from it.
struct WidgetSnapshot: Codable, Equatable {
    static let appGroup = "group.com.timaro.timeclock"
    static let widgetKind = "TimaroStatus"
    private static let key = "widgetSnapshot"

    /// Start of the day the "today" figures refer to.
    var day: Date
    /// Start of the running shift, nil when not clocked in.
    var sessionStart: Date?
    /// Start of the break in progress.
    var pausedAt: Date?
    /// Breaks already finished in the running shift.
    var closedBreakSeconds: TimeInterval
    /// Worked time of today's finished shifts.
    var todayClosedSeconds: TimeInterval
    /// Today's target after vacation.
    var todayTarget: TimeInterval
    /// Time account balance (finished days).
    var balance: TimeInterval
    /// Vacation days left this year.
    var vacationRemaining: Double
    var workplaceName: String?

    var isClockedIn: Bool { sessionStart != nil }
    var isPaused: Bool { isClockedIn && pausedAt != nil }

    /// Worked time of the running shift, without breaks.
    func sessionWorked(at now: Date) -> TimeInterval {
        guard let sessionStart else { return 0 }
        // A break in progress stops the clock at its start.
        let end = pausedAt ?? now
        return max(0, end.timeIntervalSince(sessionStart) - closedBreakSeconds)
    }

    /// Worked time today, including the running shift.
    func todayWorked(at now: Date, calendar: Calendar = .current) -> TimeInterval {
        let closed = calendar.isDate(day, inSameDayAs: now) ? todayClosedSeconds : 0
        return closed + sessionWorked(at: now)
    }

    /// Reference date for a counting-up `Text(_:style: .timer)` showing today's worked
    /// time. Nil while not working (not clocked in or on a break).
    func todayTimerStart(at now: Date) -> Date? {
        guard isClockedIn, !isPaused else { return nil }
        return now.addingTimeInterval(-todayWorked(at: now))
    }

    /// When today's target is reached at the current pace, if still ahead.
    func targetReachedAt(now: Date) -> Date? {
        guard isClockedIn, !isPaused else { return nil }
        let remaining = todayTarget - todayWorked(at: now)
        return remaining > 0 ? now.addingTimeInterval(remaining) : nil
    }

    // MARK: Storage

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults?.set(data, forKey: Self.key)
    }
}
