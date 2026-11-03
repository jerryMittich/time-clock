import Foundation
import SwiftData

/// Sample data for App Store screenshots. Started with the launch argument `-demoMode`
/// (Debug builds only); see `.github/workflows/screenshots.yml`.
///
/// - `-demoTab N` opens tab N (0 Clock, 1 Timesheet, 2 Vacation, 3 Workplaces, 4 Settings).
/// - `-demoEditWorkplace` opens the first workplace in the editor (map with radius).
///
/// Demo data lives in memory only, so the real store is never touched.
enum DemoMode {
    static let isActive: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demoMode")
        #else
        return false
        #endif
    }()

    static var initialTab: Int {
        isActive ? UserDefaults.standard.integer(forKey: "demoTab") : 0
    }

    static var opensWorkplaceEditor: Bool {
        isActive && ProcessInfo.processInfo.arguments.contains("-demoEditWorkplace")
    }

    static func seed(_ container: ModelContainer, now: Date = .now) {
        let context = ModelContext(container)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let text = Texts.current
        var random = SeededGenerator(seed: 42)

        let office = Workplace(name: text.office, latitude: 46.4983, longitude: 11.3548,
                               radius: 150, hourlyRate: 28, colorName: "blue")
        let client = Workplace(name: text.client, latitude: 46.4775, longitude: 11.3310,
                               radius: 200, hourlyRate: 32, colorName: "orange")
        context.insert(office)
        context.insert(client)

        // Vacation: a summer week, a recent week, a half day and a planned week.
        var vacationDays = Set<Date>()
        var halfDays = Set<Date>()
        func addWeek(startingDaysFromToday offset: Int, note: String) {
            guard let anyDay = calendar.date(byAdding: .day, value: offset, to: today),
                  let week = calendar.dateInterval(of: .weekOfYear, for: anyDay) else { return }
            for index in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: index, to: week.start),
                      !calendar.isDateInWeekend(day) else { continue }
                context.insert(VacationDay(date: day, note: note))
                vacationDays.insert(calendar.startOfDay(for: day))
            }
        }
        addWeek(startingDaysFromToday: -90, note: text.summer)
        addWeek(startingDaysFromToday: -28, note: "")
        addWeek(startingDaysFromToday: 35, note: text.trip)
        if let halfDay = previousWeekday(before: today, daysBack: 9, calendar: calendar) {
            context.insert(VacationDay(date: halfDay, isHalfDay: true, note: text.appointment))
            halfDays.insert(halfDay)
        }

        // Finished shifts on weekdays for the last ten weeks.
        for offset in 1...70 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  !calendar.isDateInWeekend(day) else { continue }
            if vacationDays.contains(day) { continue }
            let isHalfDayOff = halfDays.contains(day)

            let atClient = offset % 7 == 3
            let startMinute = 7 * 60 + 30 + Int(random.next() % 45)
            let breakMinutes = isHalfDayOff ? 0 : [30, 30, 45, 40][Int(random.next() % 4)]
            let workedMinutes = isHalfDayOff ? 4 * 60 + 5 : 7 * 60 + 50 + Int(random.next() % 50)
            let start = day.addingTimeInterval(Double(startMinute * 60))
            let session = WorkSession(start: start,
                                      end: start.addingTimeInterval(Double((workedMinutes + breakMinutes) * 60)),
                                      breakMinutes: breakMinutes,
                                      note: atClient ? text.meeting : "",
                                      isAutomatic: true,
                                      workplace: atClient ? client : office)
            session.closedAutomatically = true
            context.insert(session)
        }

        // Today's shift is running, with the lunch break already taken.
        let running = WorkSession(start: now.addingTimeInterval(-(5 * 3600 + 14 * 60)),
                                  breakMinutes: 30,
                                  isAutomatic: true,
                                  workplace: office)
        context.insert(running)

        try? context.save()
    }

    private static func previousWeekday(before date: Date, daysBack: Int, calendar: Calendar) -> Date? {
        var day = calendar.date(byAdding: .day, value: -daysBack, to: date)
        while let candidate = day, calendar.isDateInWeekend(candidate) {
            day = calendar.date(byAdding: .day, value: -1, to: candidate)
        }
        return day.map { calendar.startOfDay(for: $0) }
    }

    private struct Texts {
        var office, client, meeting, summer, trip, appointment: String

        static var current: Texts {
            switch Locale.preferredLanguages.first?.prefix(2) {
            case "de": Texts(office: "Büro", client: "Kunde Gries", meeting: "Projektbesprechung",
                             summer: "Sommerurlaub", trip: "Skiurlaub", appointment: "Arzttermin")
            case "it": Texts(office: "Ufficio", client: "Cliente Gries", meeting: "Riunione di progetto",
                             summer: "Ferie estive", trip: "Settimana bianca", appointment: "Visita medica")
            default: Texts(office: "Office", client: "Client site", meeting: "Project meeting",
                           summer: "Summer holiday", trip: "Ski trip", appointment: "Doctor's appointment")
            }
        }
    }

    /// Deterministic pseudo-random numbers, so every run produces the same shifts.
    private struct SeededGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
    }
}
