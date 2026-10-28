import Foundation
import SwiftData

/// One day (or half day) of vacation.
@Model
final class VacationDay {
    var id: UUID
    /// Start of the vacation day.
    var date: Date
    var isHalfDay: Bool
    var note: String

    init(date: Date, isHalfDay: Bool = false, note: String = "", calendar: Calendar = .current) {
        self.id = UUID()
        self.date = calendar.startOfDay(for: date)
        self.isHalfDay = isHalfDay
        self.note = note
    }

    /// Days of vacation used: 0.5 or 1.
    var amount: Double { isHalfDay ? 0.5 : 1 }
}

extension Array where Element == VacationDay {
    /// Start-of-day → days off, for the time account.
    var byDay: [Date: Double] {
        Dictionary(map { ($0.date, $0.amount) }, uniquingKeysWith: +)
    }
}
