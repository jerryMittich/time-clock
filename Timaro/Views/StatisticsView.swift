import SwiftUI
import SwiftData
import Charts

/// Statistics for a chosen period and workplace: totals, hours over time, average per
/// weekday, share per workplace, a list per day/week/month and days off.
struct StatisticsView: View {
    @Query(sort: \WorkSession.start) private var sessions: [WorkSession]
    @Query private var daysOff: [VacationDay]
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0

    @State private var period: Period = .month
    @State private var anchor = DemoMode.initialTimesheetMonth ?? Date.now
    @State private var customFrom = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customTo = Date.now
    /// nil for all workplaces, "" for shifts without a workplace.
    @State private var workplace: String?

    enum Period: CaseIterable, Identifiable {
        case week, month, year, all, custom

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .week: "Week"
            case .month: "Month"
            case .year: "Year"
            case .all: "All time"
            case .custom: "Custom"
            }
        }

        var component: Calendar.Component? {
            switch self {
            case .week: .weekOfYear
            case .month: .month
            case .year: .year
            case .all, .custom: nil
            }
        }
    }

    private var calendar: Calendar { .current }
    private var dailyTarget: TimeInterval { dailyTargetHours * 3600 }
    private var showsOvertime: Bool { workplace == nil }

    private var interval: DateInterval {
        let today = calendar.startOfDay(for: .now)
        func endOfDay(_ date: Date) -> Date {
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        }
        switch period {
        case .week, .month, .year:
            return calendar.dateInterval(of: period.component ?? .month, for: anchor)
                ?? DateInterval(start: today, end: endOfDay(today))
        case .all:
            let dates = sessions.map(\.start) + daysOff.map(\.date) + [today]
            let first = dates.min() ?? today
            let last = dates.max() ?? today
            return DateInterval(start: calendar.startOfDay(for: first), end: endOfDay(last))
        case .custom:
            let start = calendar.startOfDay(for: min(customFrom, customTo))
            return DateInterval(start: start, end: endOfDay(max(customFrom, customTo)))
        }
    }

    /// Workplace names to filter by; "" stands for shifts without a workplace.
    private var workplaceNames: [String] {
        var names = workplaces.map(\.name)
        if sessions.contains(where: { $0.workplace == nil }) { names.append("") }
        return names
    }

    var body: some View {
        let range = self.interval
        let grouping = Statistics.grouping(for: range)
        let shifts = sessions
            .filter { workplace == nil || ($0.workplace?.name ?? "") == workplace }
            .map { session in
                Statistics.Shift(start: session.start,
                                 worked: session.duration(),
                                 breaks: session.breakDuration(),
                                 earned: session.earnings(),
                                 workplace: session.workplace?.name,
                                 isOpen: session.isOpen)
            }
        let report = Statistics.report(shifts: shifts,
                                       daysOff: daysOff.statisticsEntries,
                                       in: range,
                                       dailyTarget: dailyTarget,
                                       grouping: grouping)

        NavigationStack {
            List {
                filterSection

                if report.isEmpty {
                    Section {
                        ContentUnavailableView("No data for this period",
                                               systemImage: "chart.bar",
                                               description: Text("Choose another period or workplace."))
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        tiles(report)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    if report.shifts > 0 {
                        Section {
                            hoursChart(report, grouping: grouping)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            weekdayChart(report)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            if workplace == nil && report.workplaces.count > 1 {
                                workplaceChart(report)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            }
                        }
                        detailsSection(report, grouping: grouping)
                    }

                    if report.vacation > 0 || !report.absences.isEmpty {
                        daysOffSection(report)
                    }
                }
            }
            .screenBackground()
            .navigationTitle("Statistics")
        }
    }

    // MARK: Filters

    private var filterSection: some View {
        Section {
            Picker("Period", selection: $period) {
                ForEach(Period.allCases) { Text($0.title).tag($0) }
            }
            .onChange(of: period) { anchor = .now }

            if let component = period.component {
                HStack {
                    Button { shift(component, by: -1) } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel(Text("Previous period"))
                    Spacer()
                    Text(periodTitle)
                        .font(.headline)
                        .monospacedDigit()
                    Spacer()
                    Button { shift(component, by: 1) } label: { Image(systemName: "chevron.right") }
                        .accessibilityLabel(Text("Next period"))
                }
                // Two buttons in one row: each must only react to its own taps.
                .buttonStyle(.borderless)
            }

            if period == .custom {
                DatePicker("From", selection: $customFrom, displayedComponents: .date)
                DatePicker("To", selection: $customTo, in: customFrom..., displayedComponents: .date)
            }

            if workplaceNames.count > 1 {
                Picker("Workplace", selection: $workplace) {
                    Text("All workplaces").tag(String?.none)
                    ForEach(workplaceNames, id: \.self) { name in
                        Text(displayName(name)).tag(Optional(name))
                    }
                }
            }
        }
    }

    private func shift(_ component: Calendar.Component, by value: Int) {
        if let date = calendar.date(byAdding: component, value: value, to: anchor) {
            withAnimation { anchor = date }
        }
    }

    private var periodTitle: String {
        switch period {
        case .week:
            let start = interval.start
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let week = String(localized: "Week \(String(calendar.component(.weekOfYear, from: start)))")
            return "\(week) · \(start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month()))"
        case .month:
            return anchor.formatted(.dateTime.month(.wide).year())
        case .year:
            return String(calendar.component(.year, from: anchor))
        case .all, .custom:
            return ""
        }
    }

    private func displayName(_ workplace: String) -> String {
        workplace.isEmpty ? String(localized: "No workplace") : workplace
    }

    // MARK: Tiles

    private func tiles(_ report: Statistics.Report) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(title: "Worked", value: Formatters.duration(report.worked), systemImage: "clock")
            if showsOvertime {
                StatTile(title: "Difference", value: Formatters.signedDuration(report.delta),
                         systemImage: "plusminus", color: Theme.balanceColor(report.delta))
            }
            StatTile(title: "Work days", value: "\(report.workDays)", systemImage: "calendar")
            StatTile(title: "Per work day", value: Formatters.duration(report.averagePerWorkDay),
                     systemImage: "chart.line.flattrend.xyaxis")
            StatTile(title: "Breaks", value: Formatters.duration(report.breaks), systemImage: "cup.and.saucer.fill")
            if report.earned > 0 {
                StatTile(title: "Earnings", value: Formatters.currency(report.earned), systemImage: "eurosign")
            }
            if report.vacation > 0 {
                StatTile(title: "Vacation", value: Formatters.days(report.vacation),
                         systemImage: "sun.max.fill", color: Theme.pause)
            }
            if report.absenceDays > 0 {
                StatTile(title: "Absences", value: Formatters.days(report.absenceDays),
                         systemImage: "cross.case.fill", color: Theme.absence)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Charts

    private func hoursChart(_ report: Statistics.Report, grouping: Statistics.Grouping) -> some View {
        let title: LocalizedStringKey = switch grouping {
        case .day: "Hours per day"
        case .week: "Hours per week"
        case .month: "Hours per month"
        }
        let axisFormat: Date.FormatStyle = switch grouping {
        case .day: .dateTime.day()
        case .week: .dateTime.day().month(.abbreviated)
        case .month: .dateTime.month(.narrow)
        }
        return ChartCard(title: title) {
            Chart {
                ForEach(report.groups) { group in
                    BarMark(x: .value("Period", group.start, unit: grouping.component),
                            y: .value("Hours", group.worked / 3600))
                        .foregroundStyle(Theme.deepSky.gradient)
                        .cornerRadius(4)
                }
                if grouping == .day && dailyTarget > 0 {
                    RuleMark(y: .value("Target", dailyTargetHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: axisFormat)
                }
            }
            .chartYAxis { hoursAxis }
            .frame(height: 180)
        }
    }

    private func weekdayChart(_ report: Statistics.Report) -> some View {
        ChartCard(title: "Average per weekday") {
            Chart(report.weekdays) { day in
                BarMark(x: .value("Weekday", calendar.shortWeekdaySymbols[day.weekday - 1]),
                        y: .value("Hours", day.average / 3600))
                    .foregroundStyle(Theme.positive.gradient)
                    .cornerRadius(4)
            }
            .chartYAxis { hoursAxis }
            .frame(height: 150)
        }
    }

    private func workplaceChart(_ report: Statistics.Report) -> some View {
        let colors = Dictionary(workplaces.map { ($0.name, Color.named($0.colorName)) },
                                uniquingKeysWith: { first, _ in first })
        return ChartCard(title: "Hours per workplace") {
            HStack(spacing: 16) {
                Chart(report.workplaces) { share in
                    SectorMark(angle: .value("Hours", share.worked), innerRadius: .ratio(0.6), angularInset: 1.5)
                        .foregroundStyle(colors[share.name] ?? .gray)
                        .cornerRadius(3)
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(report.workplaces) { share in
                        HStack(spacing: 8) {
                            Circle().fill(colors[share.name] ?? .gray).frame(width: 9, height: 9)
                            Text(displayName(share.name)).lineLimit(1)
                            Spacer()
                            Text(Formatters.duration(share.worked)).monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var hoursAxis: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
            AxisGridLine()
            AxisValueLabel {
                if let hours = value.as(Double.self) {
                    Text("\(Int(hours)) h")
                }
            }
        }
    }

    // MARK: Lists

    private func detailsSection(_ report: Statistics.Report, grouping: Statistics.Grouping) -> some View {
        let header: LocalizedStringKey = switch grouping {
        case .day: "Days"
        case .week: "Weeks"
        case .month: "Months"
        }
        return Section(header) {
            ForEach(Array(report.groups.filter { $0.worked > 0 }.reversed())) { group in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label(for: group, grouping: grouping))
                        if group.earned > 0 {
                            Text(Formatters.currency(group.earned))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Formatters.duration(group.worked))
                            .monospacedDigit()
                        if showsOvertime {
                            Text(Formatters.signedDuration(group.delta))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(Theme.balanceColor(group.delta))
                        }
                    }
                }
            }
        }
    }

    private func daysOffSection(_ report: Statistics.Report) -> some View {
        Section("Days off") {
            if report.vacation > 0 {
                LabeledContent {
                    Text(Formatters.days(report.vacation))
                } label: {
                    Label("Vacation", systemImage: "sun.max.fill")
                }
            }
            ForEach(report.absences.sorted { $0.value > $1.value }, id: \.key) { entry in
                LabeledContent {
                    Text(Formatters.days(entry.value))
                } label: {
                    Label(entry.key, systemImage: "cross.case.fill")
                }
            }
        }
    }

    private func label(for group: Statistics.Group, grouping: Statistics.Grouping) -> String {
        switch grouping {
        case .day:
            return group.start.formatted(.dateTime.weekday(.abbreviated).day().month())
        case .week:
            let end = calendar.date(byAdding: .day, value: 6, to: group.start) ?? group.start
            let week = String(localized: "Week \(String(calendar.component(.weekOfYear, from: group.start)))")
            return "\(week) · \(group.start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month()))"
        case .month:
            return group.start.formatted(.dateTime.month(.wide).year())
        }
    }
}

/// A titled glass card around a chart.
private struct ChartCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding(16)
        .glassCard(cornerRadius: 26)
        .padding(.vertical, 4)
    }
}
