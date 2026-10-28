import Foundation
import SwiftData
import CoreLocation

@Model
final class Workplace {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    /// Geofence radius in metres (iOS honours roughly 100–1000 m reliably).
    var radius: Double
    var hourlyRate: Double
    var autoTrack: Bool
    var colorName: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \WorkSession.workplace)
    var sessions: [WorkSession] = []

    init(name: String,
         latitude: Double,
         longitude: Double,
         radius: Double = 150,
         hourlyRate: Double = 0,
         autoTrack: Bool = true,
         colorName: String = "blue") {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.hourlyRate = hourlyRate
        self.autoTrack = autoTrack
        self.colorName = colorName
        self.createdAt = .now
    }

    var coordinate: CLLocationCoordinate2D {
        get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    /// Identifier used for the CoreLocation region.
    var regionIdentifier: String { id.uuidString }
}
