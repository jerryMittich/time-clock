import Foundation
import SwiftData

/// Single model container shared by the UI and background geofence handling.
enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Workplace.self, WorkSession.self, VacationDay.self)
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }()
}
