import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var sessions: [WorkSession]
    @AppStorage(AppSettings.Key.notifyOnAutoPunch) private var notifyOnAutoPunch = true
    @AppStorage(AppSettings.Key.roundingMinutes) private var roundingMinutes = 0
    @AppStorage(AppSettings.Key.exitDelayMinutes) private var exitDelayMinutes = 5
    @AppStorage(AppSettings.Key.weeklyTargetHours) private var weeklyTargetHours = 40.0

    private let monitor = LocationMonitor.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Automatic tracking") {
                    LabeledContent("Location access", value: authorizationText)
                    if !monitor.hasAlwaysAuthorization {
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    Toggle("Notify on automatic punches", isOn: $notifyOnAutoPunch)
                        .onChange(of: notifyOnAutoPunch) { _, on in
                            if on { NotificationService.requestAuthorization() }
                        }
                    Picker("Resume shift if back within", selection: $exitDelayMinutes) {
                        Text("Off").tag(0)
                        ForEach([5, 10, 15, 30, 60], id: \.self) { Text("\($0) min").tag($0) }
                    }
                }

                Section("Timesheet") {
                    Picker("Round punches to", selection: $roundingMinutes) {
                        Text("Exact").tag(0)
                        ForEach([5, 10, 15, 30], id: \.self) { Text("\($0) min").tag($0) }
                    }
                    Stepper("Weekly target: \(Int(weeklyTargetHours)) h",
                            value: $weeklyTargetHours, in: 0...80, step: 1)
                }

                Section("Data") {
                    if let url = try? CSVExporter.export(sessions) {
                        ShareLink(item: url) {
                            Label("Export all shifts (CSV)", systemImage: "square.and.arrow.up")
                        }
                    }
                    Text("All data is stored only on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent("Version",
                                   value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var authorizationText: String {
        switch monitor.authorization {
        case .authorizedAlways: String(localized: "Always")
        case .authorizedWhenInUse: String(localized: "While using")
        case .denied, .restricted: String(localized: "Denied")
        default: String(localized: "Not set")
        }
    }
}
