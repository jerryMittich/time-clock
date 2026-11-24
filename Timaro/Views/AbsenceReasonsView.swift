import SwiftUI

/// Edits the absence reasons (sick leave, paternity leave, …) offered when entering a day off.
struct AbsenceReasonsView: View {
    @State private var reasons = AppSettings.absenceReasons
    @State private var newReason = ""

    private var trimmed: String { newReason.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canAdd: Bool { !trimmed.isEmpty && !reasons.contains(trimmed) }

    var body: some View {
        List {
            Section {
                ForEach(reasons, id: \.self) { reason in
                    Label(reason, systemImage: "cross.case.fill")
                        .labelStyle(TintedIconLabelStyle(color: Theme.absence))
                }
                .onDelete { reasons.remove(atOffsets: $0) }
                .onMove { reasons.move(fromOffsets: $0, toOffset: $1) }

                HStack {
                    TextField("New reason", text: $newReason)
                        .onSubmit(add)
                        .submitLabel(.done)
                    Button("Add", action: add)
                        .disabled(!canAdd)
                }
            } footer: {
                Text("Choose these when you enter a day off that isn't vacation. Absences lower that day's target like vacation, but don't count against your vacation allowance. Removing a reason keeps the days already entered with it.")
            }
        }
        .screenBackground()
        .navigationTitle("Absence reasons")
        .toolbar { EditButton() }
        .onChange(of: reasons) { _, value in AppSettings.absenceReasons = value }
    }

    private func add() {
        guard canAdd else { return }
        withAnimation { reasons.append(trimmed) }
        newReason = ""
    }
}

private struct TintedIconLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon.foregroundStyle(color)
            configuration.title
        }
    }
}
