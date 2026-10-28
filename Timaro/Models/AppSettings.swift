import Foundation

/// Lightweight user preferences stored in UserDefaults.
enum AppSettings {
    enum Key {
        static let notifyOnAutoPunch = "notifyOnAutoPunch"
        static let roundingMinutes = "roundingMinutes"
        static let exitDelayMinutes = "exitDelayMinutes"
        static let dailyTargetHours = "dailyTargetHours"
        /// Starting balance of the time account, in minutes (may be negative).
        static let initialBalanceMinutes = "initialBalanceMinutes"
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.notifyOnAutoPunch: true,
            Key.roundingMinutes: 0,
            Key.exitDelayMinutes: 5,
            Key.dailyTargetHours: 8.0,
            Key.initialBalanceMinutes: 0
        ])
    }

    static var notifyOnAutoPunch: Bool { UserDefaults.standard.bool(forKey: Key.notifyOnAutoPunch) }
    static var roundingMinutes: Int { UserDefaults.standard.integer(forKey: Key.roundingMinutes) }
    static var exitDelayMinutes: Int { UserDefaults.standard.integer(forKey: Key.exitDelayMinutes) }

    /// Rounds a punch time to the nearest multiple of `roundingMinutes` (0 = no rounding).
    static func rounded(_ date: Date) -> Date {
        let step = roundingMinutes
        guard step > 0 else { return date }
        let interval = Double(step * 60)
        let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded() * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }
}
