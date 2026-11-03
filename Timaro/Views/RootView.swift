import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var workplaces: [Workplace]
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = DemoMode.initialTab

    var body: some View {
        TabView(selection: $tab) {
            ClockView()
                .tabItem { Label("Clock", systemImage: "clock.fill") }
                .tag(0)
            TimesheetView()
                .tabItem { Label("Timesheet", systemImage: "list.bullet.rectangle") }
                .tag(1)
            VacationView()
                .tabItem { Label("Vacation", systemImage: "sun.max.fill") }
                .tag(2)
            WorkplacesView()
                .tabItem { Label("Workplaces", systemImage: "mappin.and.ellipse") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .tint(Color.accentColor)
        .onAppear {
            // Demo data must not start real geofences.
            if !DemoMode.isActive { LocationMonitor.shared.sync(workplaces: workplaces) }
            WidgetBridge.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            // Edits made in the app (shifts, vacation, settings) reach the widgets on leaving it.
            if phase != .active { WidgetBridge.refresh() }
        }
        .onChange(of: workplaces.map(\.syncSignature)) {
            if !DemoMode.isActive { LocationMonitor.shared.sync(workplaces: workplaces) }
        }
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
    }
}

private extension Workplace {
    /// Changes whenever something affecting the geofence changes.
    var syncSignature: String { "\(id)|\(latitude)|\(longitude)|\(radius)|\(autoTrack)" }
}
