import Foundation
import SwiftData

/// One day (or half day) off: vacation, or another absence such as sick leave.
@Model
final class VacationDay {
    var id: UUID
    /// Start of the day off.
    var date: Date
    var isHalfDay: Bool
    var note: String
    /// Absence reason from the settings (e.g. "Sick leave"); empty for vacation.
    /// Only vacation counts against the yearly allowance; every day off lowers that day's target.
    var reason: String = ""

    init(date: Date, isHalfDay: Bool = false, note: String = "", reason: String = "", calendar: Calendar = .current) {
        self.id = UUID()
        self.date = calendar.startOfDay(for: date)
        self.isHalfDay = isHalfDay
        self.note = note
        self.reason = reason
    }

    /// Days off: 0.5 or 1.
    var amount: Double { isHalfDay ? 0.5 : 1 }

    var isVacation: Bool { reason.isEmpty }
}

extension Array where Element == VacationDay {
    /// Start-of-day → days off (vacation and other absences), for the time account.
    var byDay: [Date: Double] {
        Dictionary(map { ($0.date, $0.amount) }, uniquingKeysWith: +)
    }

    /// Vacation only, for the yearly allowance.
    var vacationLedgerEntries: [VacationLedger.Entry] {
        filter(\.isVacation).map(\.ledgerEntry)
    }

    var statisticsEntries: [Statistics.DayOff] {
        map { Statistics.DayOff(date: $0.date, amount: $0.amount, reason: $0.reason) }
    }
}

/// What is off on one day, split into vacation and other absences, for charts and labels.
struct DayOffInfo: Equatable {
    var vacation: Double = 0
    var absence: Double = 0
    /// Absence reasons on this day, in entry order.
    var reasons: [String] = []

    var total: Double { min(1, vacation + absence) }

    /// "Vacation", "Half day off", "Sick leave", "Sick leave · half day".
    var title: String {
        if let reason = reasons.first, absence >= vacation {
            return absence < 1 ? String(localized: "\(reason) · half day") : reason
        }
        return vacation < 1 ? String(localized: "Half day off") : String(localized: "Vacation")
    }

    var systemImage: String {
        absence > vacation ? "cross.case.fill" : (total < 1 ? "sun.haze.fill" : "sun.max.fill")
    }
}

extension Array where Element == VacationDay {
    var infoByDay: [Date: DayOffInfo] {
        var result: [Date: DayOffInfo] = [:]
        for day in self {
            var info = result[day.date] ?? DayOffInfo()
            if day.isVacation {
                info.vacation += day.amount
            } else {
                info.absence += day.amount
                info.reasons.append(day.reason)
            }
            result[day.date] = info
        }
        return result
    }
}
