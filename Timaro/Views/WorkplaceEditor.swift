import SwiftUI
import SwiftData
import MapKit

/// Edits an existing workplace, or creates a new one when `workplace` is nil.
struct WorkplaceEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let workplace: Workplace?

    @State private var name = ""
    @State private var center = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
    @State private var radius: Double = 150
    @State private var hourlyRate: Double = 0
    @State private var autoTrack = true
    @State private var colorName = "blue"
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Color", selection: $colorName) {
                        ForEach(Color.workplacePalette, id: \.self) { name in
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color.named(name))
                                .tag(name)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Search address", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .onSubmit(search)
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            if let coordinate = item.placemark.location?.coordinate {
                                setCenter(coordinate)
                                if name.isEmpty { name = item.name ?? "" }
                            }
                            searchResults = []
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "")
                                Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    map
                        .frame(height: 260)
                        .listRowInsets(EdgeInsets())
                    Button {
                        if let coordinate = LocationMonitor.shared.lastLocation?.coordinate {
                            setCenter(coordinate)
                        } else {
                            LocationMonitor.shared.requestCurrentLocation()
                        }
                    } label: {
                        Label("Use current location", systemImage: "location.fill")
                    }
                    VStack(alignment: .leading) {
                        Text("Radius: \(Int(radius)) m")
                        Slider(value: $radius, in: 100...1000, step: 25)
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Tap the map to move the pin. A radius of at least 150 m gives the most reliable results.")
                }

                Section {
                    Toggle("Clock in/out automatically", isOn: $autoTrack)
                    LabeledContent("Hourly rate") {
                        TextField("0", value: $hourlyRate, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .screenBackground()
            .navigationTitle(workplace == nil ? LocalizedStringKey("New workplace") : "Edit workplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var map: some View {
        MapReader { proxy in
            Map(position: $camera) {
                MapCircle(center: center, radius: radius)
                    .foregroundStyle(Color.named(colorName).opacity(0.25))
                    .stroke(Color.named(colorName), lineWidth: 2)
                Marker(name.isEmpty ? String(localized: "Workplace") : name, coordinate: center)
                    .tint(Color.named(colorName))
                UserAnnotation()
            }
            .onTapGesture { point in
                if let coordinate = proxy.convert(point, from: .local) {
                    center = coordinate
                }
            }
        }
    }

    private func setCenter(_ coordinate: CLLocationCoordinate2D) {
        center = coordinate
        camera = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200))
    }

    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        Task {
            let response = try? await MKLocalSearch(request: request).start()
            searchResults = Array((response?.mapItems ?? []).prefix(5))
        }
    }

    private func load() {
        if let workplace {
            name = workplace.name
            radius = workplace.radius
            hourlyRate = workplace.hourlyRate
            autoTrack = workplace.autoTrack
            colorName = workplace.colorName
            setCenter(workplace.coordinate)
        } else if let coordinate = LocationMonitor.shared.lastLocation?.coordinate {
            setCenter(coordinate)
        } else {
            LocationMonitor.shared.requestCurrentLocation()
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let workplace {
            workplace.name = trimmed
            workplace.coordinate = center
            workplace.radius = radius
            workplace.hourlyRate = hourlyRate
            workplace.autoTrack = autoTrack
            workplace.colorName = colorName
        } else {
            context.insert(Workplace(name: trimmed,
                                     latitude: center.latitude,
                                     longitude: center.longitude,
                                     radius: radius,
                                     hourlyRate: hourlyRate,
                                     autoTrack: autoTrack,
                                     colorName: colorName))
        }
        try? context.save()
        if autoTrack { LocationMonitor.shared.requestAuthorization() }
        dismiss()
    }
}
