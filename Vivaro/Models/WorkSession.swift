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

    /// Worked time in seconds, excluding breaks. Open sessions are measured up to `now`.
    func duration(now: Date = .now) -> TimeInterval {
        let raw = (end ?? now).timeIntervalSince(start)
        return max(0, raw - Double(breakMinutes * 60))
    }

    func earnings(now: Date = .now) -> Double {
        (workplace?.hourlyRate ?? 0) * duration(now: now) / 3600
    }
}
