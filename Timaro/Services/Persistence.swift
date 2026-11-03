import Foundation
import SwiftData

/// Single model container shared by the UI and background geofence handling.
enum Persistence {
    static let container: ModelContainer = {
        do {
            if DemoMode.isActive {
                let container = try ModelContainer(for: Workplace.self, WorkSession.self, VacationDay.self,
                                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                DemoMode.seed(container)
                return container
            }
            return try ModelContainer(for: Workplace.self, WorkSession.self, VacationDay.self)
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }()
}
