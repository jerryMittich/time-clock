import Foundation

enum Formatters {
    /// "7h 42m" style duration.
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds) / 60
        return String(format: "%dh %02dm", total / 60, total % 60)
    }

    /// "+1h 05m" / "−0h 30m" style balance.
    static func signedDuration(_ seconds: TimeInterval) -> String {
        let sign = seconds < -30 ? "−" : "+"
        return sign + duration(abs(seconds))
    }

    /// "07:42:10" style running clock.
    static func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    /// Decimal hours, e.g. 7.70, for exports.
    static func decimalHours(_ seconds: TimeInterval) -> String {
        String(format: "%.2f", seconds / 3600)
    }

    /// "1 day" / "2.5 days", localized.
    static func days(_ value: Double) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0...1)))
        return value == 1 ? String(localized: "1 day") : String(localized: "\(number) days")
    }

    static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }
}
