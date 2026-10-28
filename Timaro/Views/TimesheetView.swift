import SwiftUI
import SwiftData

struct TimesheetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]

    @State private var editing: WorkSession?
    @State private var addingNew = false
    @State private var exportURL: URL?
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0
    @AppStorage(AppSettings.Key.initialBalanceMinutes) private var initialBalanceMinutes = 0

    private var days: [(day: TimeAccount.Day, sessions: [WorkSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.start) }
        return TimeAccount.days(sessions.map { $0.accountEntry() }, target: dailyTargetHours * 3600)
            .map { ($0, grouped[$0.date] ?? []) }
    }

    private var balance: TimeInterval {
        TimeAccount.balance(sessions.map { $0.accountEntry() },
                            target: dailyTargetHours * 3600,
                            initial: Double(initialBalanceMinutes * 60))
    }

    var body: some View {
        NavigationStack {
            List {
                if !sessions.isEmpty {
                    Section {
                        LabeledContent("Time account") {
                            Text(Formatters.signedDuration(balance))
                                .monospacedDigit()
                                .foregroundStyle(balance < -30 ? .red : (balance > 30 ? .green : .primary))
                        }
                    } footer: {
                        Text("Time above \(Formatters.duration(dailyTargetHours * 3600)) per day is added to the account; shorter days are covered from it.")
                    }
                }
                ForEach(days, id: \.day.id) { entry in
                    Section {
                        ForEach(entry.sessions) { session in
                            Button { editing = session } label: { SessionRow(session: session) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            offsets.map { entry.sessions[$0] }.forEach { context.delete($0) }
                        }
                    } header: {
                        HStack {
                            Text(entry.day.date.formatted(.dateTime.weekday(.wide).day().month()))
                            Spacer()
                            Text(Formatters.duration(entry.day.worked))
                                .monospacedDigit()
                            if !entry.day.inProgress {
                                Text(Formatters.signedDuration(entry.day.delta))
                                    .monospacedDigit()
                                    .foregroundStyle(entry.day.delta < -30 ? .red : .green)
                            }
                        }
                    }
                }
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView("No shifts yet",
                                           systemImage: "clock.badge.questionmark",
                                           description: Text("Clock in manually or add a workplace to track automatically."))
                }
            }
            .navigationTitle("Timesheet")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let exportURL {
                        ShareLink(item: exportURL) { Label("Export", systemImage: "square.and.arrow.up") }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addingNew = true } label: { Label("Add shift", systemImage: "plus") }
                }
            }
            .task(id: sessions.count) { exportURL = try? CSVExporter.export(sessions) }
            .sheet(item: $editing) { session in
                SessionEditor(session: session)
            }
            .sheet(isPresented: $addingNew) {
                SessionEditor(session: nil)
            }
        }
    }
}

private struct SessionRow: View {
    let session: WorkSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(timeRange)
                        .font(.headline)
                    if session.isAutomatic {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                if session.breakMinutes > 0 || session.isPaused {
                    Text("Breaks: \(Formatters.duration(session.breakDuration()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let name = session.workplace?.name {
                    Text(name).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.duration(session.duration()))
                    .font(.headline)
                    .monospacedDigit()
                if session.earnings() > 0 {
                    Text(Formatters.currency(session.earnings()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var timeRange: String {
        let start = session.start.formatted(date: .omitted, time: .shortened)
        guard let end = session.end else { return "\(start) – …" }
        return "\(start) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}
