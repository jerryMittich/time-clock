import SwiftUI
import SwiftData

struct VacationView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VacationDay.date, order: .reverse) private var vacationDays: [VacationDay]

    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var allowance = AppSettings.vacationAllowance(for: Calendar.current.component(.year, from: .now))
    @State private var adding = false

    private var daysInYear: [VacationDay] {
        vacationDays.filter { Calendar.current.component(.year, from: $0.date) == year }
    }

    private var months: [(month: Date, days: [VacationDay])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: daysInYear) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        let summary = VacationLedger.summary(daysInYear.map(\.ledgerEntry), year: year, allowance: allowance)

        NavigationStack {
            List {
                Section {
                    summaryCard(summary)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if months.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No vacation yet", systemImage: "sun.max")
                        } description: {
                            Text("Add your days off. Half days are possible too.")
                        } actions: {
                            Button("Add vacation") { adding = true }
                                .prominentButton()
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                ForEach(months, id: \.month) { entry in
                    Section {
                        ForEach(entry.days) { day in
                            VacationRow(day: day)
                        }
                        .onDelete { offsets in
                            offsets.map { entry.days[$0] }.forEach { context.delete($0) }
                        }
                    } header: {
                        HStack {
                            Text(entry.month.formatted(.dateTime.month(.wide)))
                            Spacer()
                            Text(Formatters.days(entry.days.reduce(0) { $0 + $1.amount }))
                        }
                    }
                }
            }
            .screenBackground()
            .navigationTitle("Vacation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Label("Add vacation", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $adding) {
                AddVacationSheet(defaultDate: defaultDateForYear)
            }
            .onChange(of: year) { _, newYear in
                allowance = AppSettings.vacationAllowance(for: newYear)
            }
            .onChange(of: allowance) { _, value in
                AppSettings.setVacationAllowance(value, for: year)
            }
        }
    }

    private var defaultDateForYear: Date {
        let calendar = Calendar.current
        if calendar.component(.year, from: .now) == year { return .now }
        return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? .now
    }

    private func summaryCard(_ summary: VacationLedger.Summary) -> some View {
        let used = summary.taken + summary.planned
        return VStack(spacing: 18) {
            HStack {
                Button { year -= 1 } label: { Image(systemName: "chevron.left") }
                    .padding(10)
                    .glassCapsule()
                Spacer()
                Text(String(year))
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Spacer()
                Button { year += 1 } label: { Image(systemName: "chevron.right") }
                    .padding(10)
                    .glassCapsule()
            }
            .buttonStyle(.plain)

            ProgressRing(progress: summary.allowance > 0 ? used / summary.allowance : 0, lineWidth: 14) {
                VStack(spacing: 2) {
                    Text(summary.remaining.formatted(.number.precision(.fractionLength(0...1))))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(summary.remaining < 0 ? Theme.negative : .primary)
                    Text("days left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            HStack(spacing: 10) {
                figure("Allowance", summary.allowance)
                figure("Taken", summary.taken)
                figure("Planned", summary.planned)
            }

            Stepper(value: $allowance, in: 0...100, step: 0.5) {
                Text("Allowance \(String(year)): \(Formatters.days(allowance))")
                    .font(.subheadline)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 30)
        .padding(.vertical, 4)
    }

    private func figure(_ title: LocalizedStringKey, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(value.formatted(.number.precision(.fractionLength(0...1))))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 16)
    }
}

private struct VacationRow: View {
    let day: VacationDay

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: day.isHalfDay ? "sun.haze.fill" : "sun.max.fill")
                .font(.title3)
                .foregroundStyle(Theme.pause)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.body.weight(.medium))
                if !day.note.isEmpty {
                    Text(day.note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(day.isHalfDay ? LocalizedStringKey("Half day") : "Full day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Adds one day, half a day, or a range of days.
struct AddVacationSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [VacationDay]

    @State private var from: Date
    @State private var to: Date
    @State private var isHalfDay = false
    @State private var skipWeekends = true
    @State private var note = ""

    init(defaultDate: Date) {
        _from = State(initialValue: defaultDate)
        _to = State(initialValue: defaultDate)
    }

    private var isSingleDay: Bool { Calendar.current.isDate(from, inSameDayAs: to) }

    private var dates: [Date] {
        VacationLedger.days(from: from, to: to, skipWeekends: skipWeekends && !isSingleDay)
    }

    private var total: Double {
        isSingleDay && isHalfDay ? 0.5 : Double(dates.count)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("From", selection: $from, displayedComponents: .date)
                        .onChange(of: from) { _, value in
                            if to < value { to = value }
                        }
                    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
                    if isSingleDay {
                        Toggle("Half day", isOn: $isHalfDay)
                    } else {
                        Toggle("Skip weekends", isOn: $skipWeekends)
                    }
                } footer: {
                    Text("That is \(Formatters.days(total)) of vacation.")
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                }
            }
            .screenBackground()
            .navigationTitle("Add vacation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(dates.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let halfDay = isSingleDay && isHalfDay
        for date in dates {
            // Re-entering a day replaces the earlier entry instead of counting it twice.
            for old in existing where Calendar.current.isDate(old.date, inSameDayAs: date) {
                context.delete(old)
            }
            context.insert(VacationDay(date: date, isHalfDay: halfDay, note: note))
        }
        try? context.save()
        dismiss()
    }
}
