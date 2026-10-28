import Foundation

enum CSVExporter {
    /// Writes the sessions to a temporary CSV file and returns its URL.
    static func export(_ sessions: [WorkSession]) throws -> URL {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        var lines = ["Workplace,Start,End,Break (min),Hours,Earnings,Automatic,Note"]
        for session in sessions.sorted(by: { $0.start < $1.start }) {
            let fields = [
                session.workplace?.name ?? "",
                dateFormatter.string(from: session.start),
                session.end.map(dateFormatter.string(from:)) ?? "",
                String(session.breakMinutes),
                Formatters.decimalHours(session.duration()),
                String(format: "%.2f", session.earnings()),
                session.isAutomatic ? "yes" : "no",
                session.note
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("timaro-timesheet-\(Int(Date().timeIntervalSince1970)).csv")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
