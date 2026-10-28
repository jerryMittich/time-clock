import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var sessions: [WorkSession]
    @AppStorage(AppSettings.Key.notifyOnAutoPunch) private var notifyOnAutoPunch = true
    @AppStorage(AppSettings.Key.roundingMinutes) private var roundingMinutes = 0
    @AppStorage(AppSettings.Key.exitDelayMinutes) private var exitDelayMinutes = 5
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0
    @AppStorage(AppSettings.Key.initialBalanceMinutes) private var initialBalanceMinutes = 0

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

                Section {
                    Stepper("Daily target: \(Formatters.duration(dailyTargetHours * 3600))",
                            value: $dailyTargetHours, in: 0...12, step: 0.5)
                    Stepper("Starting balance: \(Formatters.signedDuration(Double(initialBalanceMinutes * 60)))",
                            value: $initialBalanceMinutes, in: -12_000...12_000, step: 15)
                } header: {
                    Text("Time account")
                } footer: {
                    Text("Use the starting balance to carry over existing overtime or to correct the account.")
                }

                Section("Timesheet") {
                    Picker("Round punches to", selection: $roundingMinutes) {
                        Text("Exact").tag(0)
                        ForEach([5, 10, 15, 30], id: \.self) { Text("\($0) min").tag($0) }
                    }
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
            .screenBackground()
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
