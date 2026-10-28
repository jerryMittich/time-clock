import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var workplaces: [Workplace]
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        TabView {
            ClockView()
                .tabItem { Label("Clock", systemImage: "clock.fill") }
            TimesheetView()
                .tabItem { Label("Timesheet", systemImage: "list.bullet.rectangle") }
            VacationView()
                .tabItem { Label("Vacation", systemImage: "sun.max.fill") }
            WorkplacesView()
                .tabItem { Label("Workplaces", systemImage: "mappin.and.ellipse") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color.accentColor)
        .onAppear { LocationMonitor.shared.sync(workplaces: workplaces) }
        .onChange(of: workplaces.map(\.syncSignature)) {
            LocationMonitor.shared.sync(workplaces: workplaces)
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
