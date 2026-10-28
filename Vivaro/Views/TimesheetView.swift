import SwiftUI
import SwiftData

struct TimesheetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]

    @State private var editing: WorkSession?
    @State private var addingNew = false
    @State private var exportURL: URL?

    private var weeks: [(start: Date, sessions: [WorkSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) {
            calendar.dateInterval(of: .weekOfYear, for: $0.start)?.start ?? $0.start
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(weeks, id: \.start) { week in
                    Section {
                        ForEach(week.sessions) { session in
                            Button { editing = session } label: { SessionRow(session: session) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            offsets.map { week.sessions[$0] }.forEach { context.delete($0) }
                        }
                    } header: {
                        HStack {
                            Text("Week of \(week.start.formatted(date: .abbreviated, time: .omitted))")
                            Spacer()
                            Text(Formatters.duration(week.sessions.reduce(0) { $0 + $1.duration() }))
                                .monospacedDigit()
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
                    Text(session.start.formatted(.dateTime.weekday(.abbreviated).day().month()))
                        .font(.headline)
                    if session.isAutomatic {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                Text(timeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
