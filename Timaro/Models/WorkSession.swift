import Foundation
import SwiftData

@Model
final class WorkSession {
    var id: UUID
    var start: Date
    var end: Date?
    var breakMinutes: Int
    var note: String
    /// True when the session was opened by a geofence event rather than a manual punch.
    var isAutomatic: Bool
    /// True when the session was closed by leaving the geofence. Such sessions can be
    /// reopened if the user comes back within the exit grace period.
    var closedAutomatically: Bool = false
    /// Start of the break currently in progress; nil while working or after the shift ended.
    var pausedAt: Date? = nil
    var workplace: Workplace?

    init(start: Date = .now,
         end: Date? = nil,
         breakMinutes: Int = 0,
         note: String = "",
         isAutomatic: Bool = false,
         workplace: Workplace? = nil) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.breakMinutes = breakMinutes
        self.note = note
        self.isAutomatic = isAutomatic
        self.workplace = workplace
    }

    var isOpen: Bool { end == nil }
    var isPaused: Bool { isOpen && pausedAt != nil }

    /// Worked time in seconds, excluding breaks. Open sessions are measured up to `now`,
    /// and a break in progress stops the clock.
    func duration(now: Date = .now) -> TimeInterval {
        let raw = (end ?? now).timeIntervalSince(start)
        return max(0, raw - breakDuration(now: now))
    }

    /// Total break time in seconds, including a break still in progress.
    func breakDuration(now: Date = .now) -> TimeInterval {
        var total = Double(breakMinutes * 60)
        if let pausedAt, isOpen {
            total += max(0, now.timeIntervalSince(pausedAt))
        }
        return total
    }

    func startBreak(at date: Date = .now) {
        guard isOpen, pausedAt == nil else { return }
        pausedAt = max(start, date)
    }

    func endBreak(at date: Date = .now) {
        guard let pausedAt else { return }
        breakMinutes += Int((max(0, date.timeIntervalSince(pausedAt)) / 60).rounded())
        self.pausedAt = nil
    }

    /// Ends the shift, closing a break that is still running.
    func close(at date: Date) {
        let end = max(start, date)
        endBreak(at: end)
        self.end = end
    }

    func earnings(now: Date = .now) -> Double {
        (workplace?.hourlyRate ?? 0) * duration(now: now) / 3600
    }
}
