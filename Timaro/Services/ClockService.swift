import Foundation
import SwiftData

/// All clock-in / clock-out logic lives here so manual punches and geofence events
/// follow the same rules.
@MainActor
final class ClockService {
    static let shared = ClockService(context: Persistence.container.mainContext)

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Queries

    func openSession() -> WorkSession? {
        var descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate { $0.end == nil },
            sortBy: [SortDescriptor(\.start, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func workplace(regionIdentifier: String) -> Workplace? {
        guard let id = UUID(uuidString: regionIdentifier) else { return nil }
        let descriptor = FetchDescriptor<Workplace>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: Manual punches

    @discardableResult
    func clockIn(at workplace: Workplace?, automatic: Bool = false, date: Date = .now) -> WorkSession {
        if let open = openSession() { return open }
        let session = WorkSession(start: AppSettings.rounded(date), isAutomatic: automatic, workplace: workplace)
        context.insert(session)
        save()
        return session
    }

    func clockOut(date: Date = .now, automatic: Bool = false) {
        guard let session = openSession() else { return }
        session.close(at: AppSettings.rounded(date))
        session.closedAutomatically = automatic
        save()
    }

    func startBreak(date: Date = .now) {
        guard let session = openSession() else { return }
        session.startBreak(at: date)
        save()
    }

    func endBreak(date: Date = .now) {
        guard let session = openSession() else { return }
        session.endBreak(at: date)
        save()
    }

    // MARK: Geofence events

    func handleEnter(regionIdentifier: String, date: Date = .now) {
        guard let workplace = workplace(regionIdentifier: regionIdentifier), workplace.autoTrack else { return }
        guard openSession() == nil else { return }

        // Coming back shortly after leaving (lunch run, GPS jitter) continues the same shift.
        if let recent = lastAutoClosedSession(for: workplace),
           let end = recent.end,
           date.timeIntervalSince(end) < Double(AppSettings.exitDelayMinutes * 60) {
            recent.end = nil
            recent.closedAutomatically = false
            save()
            return
        }

        clockIn(at: workplace, automatic: true, date: date)
        NotificationService.notify(
            title: String(localized: "Clocked in"),
            body: String(localized: "Arrived at \(workplace.name)")
        )
    }

    func handleExit(regionIdentifier: String, date: Date = .now) {
        guard let workplace = workplace(regionIdentifier: regionIdentifier), workplace.autoTrack else { return }
        guard let session = openSession(), session.workplace?.id == workplace.id else { return }
        clockOut(date: date, automatic: true)
        NotificationService.notify(
            title: String(localized: "Clocked out"),
            body: String(localized: "Left \(workplace.name) · \(Formatters.duration(session.duration()))")
        )
    }

    private func lastAutoClosedSession(for workplace: Workplace) -> WorkSession? {
        workplace.sessions
            .filter { $0.closedAutomatically && $0.end != nil }
            .max { ($0.end ?? .distantPast) < ($1.end ?? .distantPast) }
    }

    private func save() {
        do { try context.save() } catch { print("Save failed: \(error)") }
    }
}
