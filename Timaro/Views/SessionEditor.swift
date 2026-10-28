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
                    Stepper("Break: \(breakMinutes) min", value: $breakMinutes, in: 0...240, step: 5)
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                }
                if let session {
                    Section {
                        Button("Delete shift", role: .destructive) {
                            context.delete(session)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(session == nil ? "New shift" : "Edit shift")
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
