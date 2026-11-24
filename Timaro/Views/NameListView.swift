import SwiftUI

/// Edits a list of names stored in the settings: absence reasons (sick leave, …) offered
/// when entering a day off, or tags (home office, …) offered when editing a shift.
struct NameListView: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color
    let placeholder: LocalizedStringKey
    let footer: LocalizedStringKey
    let save: ([String]) -> Void

    @State private var names: [String]
    @State private var newName = ""

    init(title: LocalizedStringKey, systemImage: String, color: Color, placeholder: LocalizedStringKey,
         footer: LocalizedStringKey, names: [String], save: @escaping ([String]) -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.placeholder = placeholder
        self.footer = footer
        self.save = save
        _names = State(initialValue: names)
    }

    static var absenceReasons: NameListView {
        NameListView(title: "Absence reasons", systemImage: "cross.case.fill", color: Theme.absence,
                     placeholder: "New reason",
                     footer: "Choose these when you enter a day off that isn't vacation. Absences lower that day's target like vacation, but don't count against your vacation allowance. Removing a reason keeps the days already entered with it.",
                     names: AppSettings.absenceReasons) { AppSettings.absenceReasons = $0 }
    }

    static var tags: NameListView {
        NameListView(title: "Tags", systemImage: "tag.fill", color: Theme.deepSky,
                     placeholder: "New tag",
                     footer: "Choose tags when you add or edit a shift, and filter by them in the statistics. Removing a tag keeps it on the shifts that already have it.",
                     names: AppSettings.tags) { AppSettings.tags = $0 }
    }

    private var trimmed: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canAdd: Bool { !trimmed.isEmpty && !names.contains(trimmed) }

    var body: some View {
        List {
            Section {
                ForEach(names, id: \.self) { name in
                    HStack(spacing: 12) {
                        Image(systemName: systemImage).foregroundStyle(color)
                        Text(name)
                    }
                }
                .onDelete { names.remove(atOffsets: $0) }
                .onMove { names.move(fromOffsets: $0, toOffset: $1) }

                HStack {
                    TextField(placeholder, text: $newName)
                        .onSubmit(add)
                        .submitLabel(.done)
                    Button("Add", action: add)
                        .disabled(!canAdd)
                }
            } footer: {
                Text(footer)
            }
        }
        .screenBackground()
        .navigationTitle(title)
        .toolbar { EditButton() }
        .onChange(of: names) { _, value in save(value) }
    }

    private func add() {
        guard canAdd else { return }
        withAnimation { names.append(trimmed) }
        newName = ""
    }
}
