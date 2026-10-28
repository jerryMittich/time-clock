import Foundation
import SwiftData

/// Imports daily totals from a time-clock CSV export, e.g.
///
///     Datum;Stunden;Sollstunden;Überstunden;Pause;Abwesenheitstyp
///     07.01.26;08:05;08:00;00:05;00:40;
///
/// Every day with worked time becomes one shift (starting 08:00, ending after the worked
/// time plus the break). Absence days (vacation, public holidays, other leave) and days
/// without worked time are skipped. Half days off ("… 1/2") are imported with their
/// listed hours, so the time account matches the source's overtime.
enum CSVImporter {
    struct Day: Equatable {
        var date: Date
        var worked: TimeInterval
        var breakMinutes: Int
    }

    struct Parsed: Equatable {
        var days: [Day] = []
        var skippedAbsences = 0
        var skippedEmpty = 0
    }

    static func decode(_ data: Data) -> String? {
        String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    static func parse(_ text: String, calendar: Calendar = .current) -> Parsed {
        let lines = text.replacingOccurrences(of: "\r", with: "").split(separator: "\n").map(String.init)
        let delimiter: Character = (lines.first { $0.contains(";") } != nil) ? ";" : ","

        // Column positions from the header, with the export's layout as fallback.
        var dateColumn = 0, hoursColumn = 1, breakColumn = 4, absenceColumn = 5
        if let header = lines.first(where: { $0.lowercased().contains("datum") || $0.lowercased().contains("date") }) {
            let names = header.split(separator: delimiter, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            func index(_ match: (String) -> Bool) -> Int? { names.firstIndex(where: match) }
            dateColumn = index { $0.hasPrefix("datum") || $0.hasPrefix("date") } ?? dateColumn
            hoursColumn = index { $0 == "stunden" || $0 == "hours" } ?? hoursColumn
            breakColumn = index { $0.hasPrefix("pause") || $0.hasPrefix("break") } ?? breakColumn
            absenceColumn = index { $0.hasPrefix("abwesen") || $0.hasPrefix("absence") } ?? absenceColumn
        }

        var result = Parsed()
        for line in lines {
            let fields = line.split(separator: delimiter, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count > hoursColumn,
                  let date = parseDate(fields[dateColumn], calendar: calendar) else { continue }

            let absence = fields.count > absenceColumn ? fields[absenceColumn] : ""
            if !absence.isEmpty && !absence.contains("1/2") {
                result.skippedAbsences += 1
                continue
            }
            let minutes = parseMinutes(fields[hoursColumn]) ?? 0
            guard minutes > 0 else {
                result.skippedEmpty += 1
                continue
            }
            let breakMinutes = fields.count > breakColumn ? max(0, parseMinutes(fields[breakColumn]) ?? 0) : 0
            result.days.append(Day(date: date, worked: Double(minutes * 60), breakMinutes: breakMinutes))
        }
        return result
    }

    /// Inserts the days as shifts, skipping days that already have shifts in the app.
    @MainActor
    static func apply(_ days: [Day], to context: ModelContext, calendar: Calendar = .current) -> (imported: Int, skippedExisting: Int) {
        let existing = Set(((try? context.fetch(FetchDescriptor<WorkSession>())) ?? [])
            .map { calendar.startOfDay(for: $0.start) })
        var imported = 0
        var skipped = 0
        for day in days {
            guard !existing.contains(day.date) else {
                skipped += 1
                continue
            }
            let start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day.date) ?? day.date
            let end = start.addingTimeInterval(day.worked + Double(day.breakMinutes * 60))
            context.insert(WorkSession(start: start, end: end, breakMinutes: day.breakMinutes, note: "Import"))
            imported += 1
        }
        try? context.save()
        return (imported, skipped)
    }

    /// "07.01.26" or "07.01.2026" → start of that day.
    static func parseDate(_ text: String, calendar: Calendar = .current) -> Date? {
        let parts = text.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 3, (1...31).contains(parts[0]), (1...12).contains(parts[1]) else { return nil }
        let year = parts[2] < 100 ? 2000 + parts[2] : parts[2]
        return calendar.date(from: DateComponents(year: year, month: parts[1], day: parts[0]))
    }

    /// "08:05" → 485, "-00:45" → -45, "1.726:39" → 103599.
    static func parseMinutes(_ text: String) -> Int? {
        var value = text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "'", with: "")
        let negative = value.hasPrefix("-")
        if negative { value.removeFirst() }
        let parts = value.split(separator: ":")
        guard parts.count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]) else { return nil }
        let total = hours * 60 + minutes
        return negative ? -total : total
    }
}
