import SwiftUI
import SwiftData

struct VacationView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VacationDay.date, order: .reverse) private var vacationDays: [VacationDay]

    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var allowance = AppSettings.vacationAllowance(for: Calendar.current.component(.year, from: .now))
    @State private var adding = false
    @State private var deleting: VacationItem?
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<PersistentIdentifier>()
    @State private var confirmingBulkDelete = false

    private var isSelecting: Bool { editMode.isEditing }

    private var daysInYear: [VacationDay] {
        vacationDays.filter { Calendar.current.component(.year, from: $0.date) == year }
    }

    /// Value snapshots of the year's days off, grouped by month (newest first).
    private var months: [(month: Date, days: [VacationItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: daysInYear.map(VacationItem.init)) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        let summary = VacationLedger.summary(daysInYear.vacationLedgerEntries, year: year, allowance: allowance)
        let absenceDays = daysInYear.filter { !$0.isVacation }.reduce(0) { $0 + $1.amount }

        NavigationStack {
            List(selection: isSelecting ? $selection : .constant([])) {
                if !isSelecting {
                    Section {
                        summaryCard(summary, absenceDays: absenceDays)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
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
                            row(day)
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
            .environment(\.editMode, $editMode)
            .screenBackground()
            .navigationTitle("Vacation")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !months.isEmpty {
                        Button(isSelecting ? LocalizedStringKey("Done") : "Select") {
                            withAnimation {
                                editMode = isSelecting ? .inactive : .active
                                selection.removeAll()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !isSelecting {
                        Button { adding = true } label: { Label("Add vacation", systemImage: "plus") }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if isSelecting {
                        Button(role: .destructive) {
                            confirmingBulkDelete = true
                        } label: {
                            Text("Delete (\(selection.count))")
                        }
                        .disabled(selection.isEmpty)
                        // Anchored at the button, so the dialog appears next to it.
                        .confirmationDialog("Delete \(selection.count) days?",
                                            isPresented: $confirmingBulkDelete,
                                            titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                context.deleteAndSave(Array(selection))
                                selection.removeAll()
                                withAnimation { editMode = .inactive }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
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

    /// A day off. Tapping it asks to delete it, with the dialog anchored at the row.
    private func row(_ day: VacationItem) -> some View {
        VacationRow(day: day)
            .contentShape(Rectangle())
            // No tap gesture while selecting, so taps select the row.
            .modifier(TapAction(enabled: !isSelecting) { deleting = day })
            .confirmationDialog(day.isVacation ? "Delete vacation day?" : "Delete absence?",
                                isPresented: Binding(get: { deleting?.id == day.id },
                                                     set: { if !$0 { deleting = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.deleteAndSave([day.id])
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    context.deleteAndSave([day.id])
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .tag(day.id)
    }

    private var defaultDateForYear: Date {
        let calendar = Calendar.current
        if calendar.component(.year, from: .now) == year { return .now }
        return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? .now
    }

    private func summaryCard(_ summary: VacationLedger.Summary, absenceDays: Double) -> some View {
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

            if absenceDays > 0 {
                Label("Other absences: \(Formatters.days(absenceDays))", systemImage: "cross.case.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.absence)
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

private struct TapAction: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}

/// Plain copy of a day off for display, so rows never read a deleted model.
private struct VacationItem: Identifiable, Hashable {
    let id: PersistentIdentifier
    let date: Date
    let isHalfDay: Bool
    let note: String
    let reason: String
    let amount: Double

    var isVacation: Bool { reason.isEmpty }

    init(_ day: VacationDay) {
        id = day.persistentModelID
        date = day.date
        isHalfDay = day.isHalfDay
        note = day.note
        reason = day.reason
        amount = day.amount
    }
}

private struct VacationRow: View {
    let day: VacationItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(day.isVacation ? Theme.pause : Theme.absence)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.body.weight(.medium))
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(day.isHalfDay ? LocalizedStringKey("Half day") : "Full day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var icon: String {
        if !day.isVacation { return "cross.case.fill" }
        return day.isHalfDay ? "sun.haze.fill" : "sun.max.fill"
    }

    /// Absence reason and note, e.g. "Sick leave · flu".
    private var subtitle: String? {
        let parts = [day.reason, day.note].filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// Adds one day, half a day, or a range of days, as vacation or another absence.
struct AddVacationSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [VacationDay]

    @State private var from: Date
    @State private var to: Date
    /// The end date follows the start date until the user picks an end date of their own.
    @State private var toWasChosen = false
    @State private var syncingTo = false
    @State private var isHalfDay = false
    @State private var skipWeekends = true
    @State private var note = ""
    /// Empty for vacation, else an absence reason from the settings.
    @State private var reason = ""

    private let reasons = AppSettings.absenceReasons

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
                if !reasons.isEmpty {
                    Section {
                        Picker("Type", selection: $reason) {
                            Text("Vacation").tag("")
                            ForEach(reasons, id: \.self) { Text($0).tag($0) }
                        }
                    } footer: {
                        Text("Other absences lower that day's target like vacation, but don't count against your vacation allowance.")
                    }
                }
                Section {
                    DatePicker("From", selection: $from, displayedComponents: .date)
                        .onChange(of: from) { _, value in
                            if (!toWasChosen || to < value) && !Calendar.current.isDate(to, inSameDayAs: value) {
                                syncingTo = true
                                to = value
                            }
                        }
                    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
                        .onChange(of: to) {
                            if syncingTo {
                                syncingTo = false
                            } else {
                                toWasChosen = true
                            }
                        }
                    if isSingleDay {
                        Toggle("Half day", isOn: $isHalfDay)
                    } else {
                        Toggle("Skip weekends", isOn: $skipWeekends)
                    }
                } footer: {
                    if reason.isEmpty {
                        Text("That is \(Formatters.days(total)) of vacation.")
                    } else {
                        Text("That is \(Formatters.days(total)) of absence.")
                    }
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                }
            }
            .screenBackground()
            .navigationTitle(reason.isEmpty ? LocalizedStringKey("Add vacation") : "Add absence")
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
            context.insert(VacationDay(date: date, isHalfDay: halfDay, note: note, reason: reason))
        }
        try? context.save()
        WidgetBridge.refresh()
        dismiss()
    }
}
