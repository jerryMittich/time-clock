import SwiftUI
import SwiftData

/// Edits an existing shift, or creates a new one when `session` is nil.
struct SessionEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]

    let session: WorkSession?

    @State private var start = Date.now.addingTimeInterval(-8 * 3600)
    @State private var end = Date.now
    @State private var isOpen = false
    @State private var breakMinutes = 0
    @State private var note = ""
    @State private var workplaceID: UUID?
    @State private var editingBreak = false
    @State private var deleteOnClose = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Workplace", selection: $workplaceID) {
                        Text("No workplace").tag(UUID?.none)
                        ForEach(workplaces) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    DatePicker("Start", selection: $start)
                    if !isOpen {
                        DatePicker("End", selection: $end, in: start...)
                    }
                    if session?.isOpen == true {
                        Toggle("Still clocked in", isOn: $isOpen)
                    }
                    Button {
                        withAnimation(.snappy) { editingBreak.toggle() }
                    } label: {
                        LabeledContent("Break") {
                            Text(Formatters.duration(Double(breakMinutes * 60)))
                                .monospacedDigit()
                                .foregroundStyle(editingBreak ? Color.accentColor : .secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    if editingBreak {
                        BreakDurationPicker(minutes: $breakMinutes)
                    }
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                }
                if let session {
                    Section {
                        Button("Delete shift", role: .destructive) {
                            // Delete once the editor is gone, so nothing reads the deleted shift.
                            deleteOnClose = true
                            dismiss()
                        }
                    }
                }
            }
            .screenBackground()
            .navigationTitle(session == nil ? LocalizedStringKey("New shift") : "Edit shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear(perform: load)
            .onDisappear {
                if deleteOnClose, let session {
                    context.deleteAndSave([session.persistentModelID])
                }
            }
        }
    }

    private func load() {
        guard let session else { return }
        start = session.start
        end = session.end ?? .now
        isOpen = session.isOpen
        breakMinutes = session.breakMinutes
        note = session.note
        workplaceID = session.workplace?.id
    }

    private func save() {
        let target = session ?? {
            let new = WorkSession()
            context.insert(new)
            return new
        }()
        target.start = start
        target.breakMinutes = breakMinutes
        if isOpen {
            target.end = nil
        } else {
            target.close(at: end)
        }
        target.note = note
        target.workplace = workplaces.first { $0.id == workplaceID }
        try? context.save()
        dismiss()
    }
}

/// Hours and minutes wheels for the break, accurate to the minute.
private struct BreakDurationPicker: View {
    @Binding var minutes: Int

    private var hours: Binding<Int> {
        Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })
    }

    private var remainder: Binding<Int> {
        Binding(get: { minutes % 60 }, set: { minutes = (minutes / 60) * 60 + $0 })
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Hours", selection: hours) {
                ForEach(0...12, id: \.self) { Text("\($0) h").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            Picker("Minutes", selection: remainder) {
                ForEach(0...59, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 150)
    }
}
