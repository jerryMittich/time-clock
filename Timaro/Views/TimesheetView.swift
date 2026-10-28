import SwiftUI
import SwiftData
import Charts

struct TimesheetView: View {
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]
    @Query private var vacationDays: [VacationDay]

    @State private var editing: WorkSession?
    @State private var addingNew = false
    @State private var exportURL: URL?
    @State private var selectedMonth = Periods.startOfMonth(.now)
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0
    @AppStorage(AppSettings.Key.initialBalanceMinutes) private var initialBalanceMinutes = 0

    private var target: TimeInterval { dailyTargetHours * 3600 }

    /// Every month from the first entry to today (or the last planned vacation).
    private var months: [Date] {
        let dates = sessions.map(\.start) + vacationDays.map(\.date) + [Date.now]
        return Periods.months(from: dates.min() ?? .now, through: dates.max() ?? .now)
    }

    var body: some View {
        let accountDays = TimeAccount.days(sessions.map { $0.accountEntry() },
                                           target: target,
                                           vacation: vacationDays.byDay)
        let balance = TimeAccount.balance(sessions.map { $0.accountEntry() },
                                          target: target,
                                          vacation: vacationDays.byDay,
                                          initial: Double(initialBalanceMinutes * 60))
        let monthList = months

        NavigationStack {
            VStack(spacing: 0) {
                monthHeader(months: monthList)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                TabView(selection: $selectedMonth) {
                    ForEach(monthList, id: \.self) { month in
                        MonthPage(month: month,
                                  sessions: sessions,
                                  accountDays: accountDays,
                                  target: target,
                                  balance: balance,
                                  editing: $editing)
                            .tag(month)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AppBackground())
            .navigationTitle("Timesheet")
            .navigationBarTitleDisplayMode(.inline)
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

    private func monthHeader(months: [Date]) -> some View {
        let index = months.firstIndex(of: selectedMonth)
        return HStack {
            Button {
                if let index, index > 0 { withAnimation { selectedMonth = months[index - 1] } }
            } label: {
                Image(systemName: "chevron.left").padding(10)
            }
            .glassCapsule()
            .disabled(index == nil || index == 0)
            .accessibilityLabel(Text("Previous month"))
            Spacer()
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .contentTransition(.numericText())
            Spacer()
            Button {
                if let index, index < months.count - 1 { withAnimation { selectedMonth = months[index + 1] } }
            } label: {
                Image(systemName: "chevron.right").padding(10)
            }
            .glassCapsule()
            .disabled(index == nil || index == months.count - 1)
            .accessibilityLabel(Text("Next month"))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month page

private struct MonthPage: View {
    @Environment(\.modelContext) private var context

    let month: Date
    let sessions: [WorkSession]
    let accountDays: [TimeAccount.Day]
    let target: TimeInterval
    let balance: TimeInterval
    @Binding var editing: WorkSession?

    @State private var weekIndex: Int?

    private var calendar: Calendar { .current }

    private var daysInMonth: [TimeAccount.Day] {
        accountDays.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    private var weeks: [Date] { Periods.weeks(inMonth: month) }

    /// The week shown in the chart: the chosen one, else the current week in the current
    /// month, else the month's last week.
    private var shownWeekIndex: Int {
        if let weekIndex { return min(weekIndex, weeks.count - 1) }
        let current = Periods.startOfWeek(.now)
        return weeks.firstIndex(of: current) ?? max(weeks.count - 1, 0)
    }

    var body: some View {
        let sessionsByDay = Dictionary(grouping: sessions.map(SessionItem.init)) { calendar.startOfDay(for: $0.start) }
        let days = daysInMonth

        List {
            Section {
                MonthSummary(days: days, balance: balance)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if !weeks.isEmpty {
                Section {
                    WeekChartCard(weekStart: weeks[shownWeekIndex],
                                  accountDays: accountDays,
                                  target: target,
                                  canGoBack: shownWeekIndex > 0,
                                  canGoForward: shownWeekIndex < weeks.count - 1,
                                  onBack: { weekIndex = shownWeekIndex - 1 },
                                  onForward: { weekIndex = shownWeekIndex + 1 })
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if days.isEmpty {
                Section {
                    ContentUnavailableView("No shifts yet",
                                           systemImage: "clock.badge.questionmark",
                                           description: Text("Clock in manually or add a workplace to track automatically."))
                        .listRowBackground(Color.clear)
                }
            }

            ForEach(days) { day in
                Section {
                    if day.vacation > 0 {
                        Label(day.vacation >= 1 ? LocalizedStringKey("Vacation") : "Half day off",
                              systemImage: day.vacation >= 1 ? "sun.max.fill" : "sun.haze.fill")
                            .foregroundStyle(Theme.pause)
                    }
                    ForEach(sessionsByDay[day.date] ?? []) { session in
                        Button {
                            editing = context.model(for: session.id) as? WorkSession
                        } label: {
                            SessionRow(session: session)
                        }
                            .buttonStyle(.plain)
                            // Long press instead of swipe, so horizontal swipes page between months.
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.deleteAndSave([session.id])
                                } label: {
                                    Label("Delete shift", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.wide).day().month()))
                        Spacer()
                        Text(Formatters.duration(day.worked))
                            .monospacedDigit()
                        if day.hasShifts && !day.inProgress {
                            Text(Formatters.signedDuration(day.delta))
                                .monospacedDigit()
                                .foregroundStyle(day.delta < -30 ? Theme.negative : Theme.positive)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Month summary

private struct MonthSummary: View {
    let days: [TimeAccount.Day]
    let balance: TimeInterval

    var body: some View {
        let worked = days.reduce(0) { $0 + $1.worked }
        let delta = days.filter { !$0.inProgress }.reduce(0) { $0 + $1.delta }
        HStack(spacing: 10) {
            StatTile(title: "Month", value: Formatters.duration(worked), systemImage: "calendar")
            StatTile(title: "Difference", value: Formatters.signedDuration(delta),
                     systemImage: "plusminus", color: Theme.balanceColor(delta))
            StatTile(title: "Time account", value: Formatters.signedDuration(balance),
                     systemImage: "hourglass", color: Theme.balanceColor(balance))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Week chart

private struct WeekChartCard: View {
    let weekStart: Date
    let accountDays: [TimeAccount.Day]
    let target: TimeInterval
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    private struct Bar: Identifiable {
        var date: Date
        var worked: Double
        var vacation: Double
        var metTarget: Bool
        var id: Date { date }
    }

    var body: some View {
        let calendar = Calendar.current
        let byDay = Dictionary(accountDays.map { ($0.date, $0) }, uniquingKeysWith: { first, _ in first })
        let targetHours = target / 3600
        let bars: [Bar] = Periods.days(ofWeek: weekStart).map { date in
            let day = byDay[date]
            let worked = (day?.worked ?? 0) / 3600
            let vacation = (day?.vacation ?? 0) * targetHours
            let dayTarget = TimeAccount.target(target, vacation: day?.vacation ?? 0) / 3600
            return Bar(date: date, worked: worked, vacation: vacation,
                       metTarget: worked > 0 && worked + 0.01 >= dayTarget)
        }
        let weekDays = bars.compactMap { byDay[$0.date] }
        let weekWorked = weekDays.reduce(0) { $0 + $1.worked }
        let weekDelta = weekDays.filter { !$0.inProgress }.reduce(0) { $0 + $1.delta }
        let maxHours = max(targetHours + 1, bars.map { $0.worked + $0.vacation }.max() ?? 0)
        let weekNumber = calendar.component(.weekOfYear, from: weekStart)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").padding(8) }
                    .glassCapsule()
                    .disabled(!canGoBack)
                    .opacity(canGoBack ? 1 : 0.35)
                    .accessibilityLabel(Text("Previous week"))
                Spacer()
                VStack(spacing: 2) {
                    Text("Week \(String(weekNumber))")
                        .font(.headline)
                    Text("\(weekStart.formatted(.dateTime.day().month())) – \(weekEnd.formatted(.dateTime.day().month()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onForward) { Image(systemName: "chevron.right").padding(8) }
                    .glassCapsule()
                    .disabled(!canGoForward)
                    .opacity(canGoForward ? 1 : 0.35)
                    .accessibilityLabel(Text("Next week"))
            }
            .buttonStyle(.plain)

            Chart {
                ForEach(bars) { bar in
                    BarMark(x: .value("Day", bar.date, unit: .day),
                            y: .value("Hours", bar.worked))
                        .foregroundStyle(bar.metTarget ? Theme.positive.gradient : Theme.deepSky.gradient)
                        .cornerRadius(6)
                    if bar.vacation > 0 {
                        BarMark(x: .value("Day", bar.date, unit: .day),
                                y: .value("Hours", bar.vacation))
                            .foregroundStyle(Theme.pause.opacity(0.55).gradient)
                            .cornerRadius(6)
                    }
                }
                if targetHours > 0 {
                    RuleMark(y: .value("Target", targetHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(domain: 0...maxHours)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours)) h")
                        }
                    }
                }
            }
            .frame(height: 170)

            HStack {
                Label(Formatters.duration(weekWorked), systemImage: "clock")
                    .monospacedDigit()
                Spacer()
                Text(Formatters.signedDuration(weekDelta))
                    .monospacedDigit()
                    .foregroundStyle(Theme.balanceColor(weekDelta))
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(16)
        .glassCard(cornerRadius: 26)
        .padding(.vertical, 4)
    }
}

// MARK: - Rows

/// Plain copy of a shift for display, so rows never read a deleted model.
private struct SessionItem: Identifiable {
    let id: PersistentIdentifier
    let start: Date
    let end: Date?
    let isAutomatic: Bool
    let isPaused: Bool
    let breakMinutes: Int
    let breakSeconds: TimeInterval
    let workplaceName: String?
    let worked: TimeInterval
    let earned: Double

    init(_ session: WorkSession) {
        id = session.persistentModelID
        start = session.start
        end = session.end
        isAutomatic = session.isAutomatic
        isPaused = session.isPaused
        breakMinutes = session.breakMinutes
        breakSeconds = session.breakDuration()
        workplaceName = session.workplace?.name
        worked = session.duration()
        earned = session.earnings()
    }
}

private struct SessionRow: View {
    let session: SessionItem

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
                    Text("Breaks: \(Formatters.duration(session.breakSeconds))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let name = session.workplaceName {
                    Text(name).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.duration(session.worked))
                    .font(.headline)
                    .monospacedDigit()
                if session.earned > 0 {
                    Text(Formatters.currency(session.earned))
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
