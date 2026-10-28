import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkSession]
    @State private var choosingImportFile = false
    @State private var pendingImport: CSVImporter.Parsed?
    @State private var importResult: (imported: Int, skippedExisting: Int)?
    @State private var importFailed = false
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
                    Button {
                        choosingImportFile = true
                    } label: {
                        Label("Import times (CSV)", systemImage: "square.and.arrow.down")
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
            .fileImporter(isPresented: $choosingImportFile,
                          allowedContentTypes: [.commaSeparatedText, .plainText, .text, .data]) { result in
                readImportFile(result)
            }
            .alert("Import times", isPresented: Binding(get: { pendingImport != nil },
                                                        set: { if !$0 { pendingImport = nil } }),
                   presenting: pendingImport) { parsed in
                Button("Import") {
                    importResult = CSVImporter.apply(parsed.days, to: context)
                    WidgetBridge.refresh()
                }
                Button("Cancel", role: .cancel) {}
            } message: { parsed in
                Text("Found \(parsed.days.count) days with working time. Skipped: \(parsed.skippedAbsences) absence days (vacation, holidays, leave) and \(parsed.skippedEmpty) days without time. Days that already have shifts in Timaro are left unchanged.")
            }
            .alert("Import finished", isPresented: Binding(get: { importResult != nil },
                                                          set: { if !$0 { importResult = nil } }),
                   presenting: importResult) { _ in
                Button("OK") {}
            } message: { result in
                Text("\(result.imported) days imported, \(result.skippedExisting) skipped because they already had shifts.")
            }
            .alert("The file could not be read.", isPresented: $importFailed) {
                Button("OK") {}
            }
        }
    }

    private func readImportFile(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let text = CSVImporter.decode(data) else {
            importFailed = true
            return
        }
        let parsed = CSVImporter.parse(text)
        if parsed.days.isEmpty {
            importFailed = true
        } else {
            pendingImport = parsed
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
