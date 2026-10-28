import SwiftUI
import SwiftData
import MapKit

struct WorkplacesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]

    @State private var editing: Workplace?
    @State private var addingNew = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(workplaces) { workplace in
                    Button { editing = workplace } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.named(workplace.colorName))
                            VStack(alignment: .leading) {
                                Text(workplace.name).font(.headline)
                                Text(workplace.autoTrack ? LocalizedStringKey("Automatic · \(Int(workplace.radius)) m") : "Manual only")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if workplace.hourlyRate > 0 {
                                Text("\(Formatters.currency(workplace.hourlyRate))/h")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    context.deleteAndSave(offsets.map { workplaces[$0] })
                }
                if workplaces.count > LocationMonitor.maxRegions {
                    Text("iOS can monitor up to \(LocationMonitor.maxRegions) places at once. Only the first \(LocationMonitor.maxRegions) are tracked automatically.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if workplaces.isEmpty {
                    ContentUnavailableView {
                        Label("No workplaces", systemImage: "mappin.slash")
                    } description: {
                        Text("Add the places where you work and Timaro will clock you in and out automatically.")
                    } actions: {
                        Button("Add workplace") { addingNew = true }
                            .prominentButton()
                    }
                }
            }
            .screenBackground()
            .navigationTitle("Workplaces")
            .toolbar {
                Button { addingNew = true } label: { Label("Add workplace", systemImage: "plus") }
            }
            .sheet(item: $editing) { WorkplaceEditor(workplace: $0) }
            .sheet(isPresented: $addingNew) { WorkplaceEditor(workplace: nil) }
        }
    }
}

extension Color {
    static let workplacePalette = ["blue", "green", "orange", "purple", "pink", "teal"]

    static func named(_ name: String) -> Color {
        switch name {
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "pink": .pink
        case "teal": .teal
        default: .blue
        }
    }
}
