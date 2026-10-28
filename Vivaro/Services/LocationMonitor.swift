import Foundation
import CoreLocation
import Observation

/// Wraps CLLocationManager region monitoring. iOS relaunches the app in the
/// background on region events, so this must be created at launch.
@Observable
final class LocationMonitor: NSObject, CLLocationManagerDelegate {
    static let shared = LocationMonitor()

    /// iOS allows at most 20 monitored regions per app.
    static let maxRegions = 20

    private let manager = CLLocationManager()
    private(set) var authorization: CLAuthorizationStatus
    private(set) var lastLocation: CLLocation?

    private override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var hasAlwaysAuthorization: Bool { authorization == .authorizedAlways }

    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func requestCurrentLocation() {
        manager.requestLocation()
    }

    /// Makes the monitored regions match the given workplaces. Unchanged regions are left
    /// alone so that re-syncing doesn't trigger a fresh state check (which would clock the
    /// user back in after a manual clock-out while still on site).
    func sync(workplaces: [Workplace]) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        let maxRadius = manager.maximumRegionMonitoringDistance
        let desired = workplaces.filter(\.autoTrack).prefix(Self.maxRegions).map { workplace in
            let region = CLCircularRegion(
                center: workplace.coordinate,
                radius: min(max(workplace.radius, 100), maxRadius),
                identifier: workplace.regionIdentifier
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            return region
        }
        let desiredByID = Dictionary(uniqueKeysWithValues: desired.map { ($0.identifier, $0) })

        var unchanged = Set<String>()
        for case let region as CLCircularRegion in manager.monitoredRegions {
            if let wanted = desiredByID[region.identifier], Self.isSame(region, wanted) {
                unchanged.insert(region.identifier)
            } else {
                manager.stopMonitoring(for: region)
            }
        }
        for region in desired where !unchanged.contains(region.identifier) {
            manager.startMonitoring(for: region)
        }
    }

    private static func isSame(_ a: CLCircularRegion, _ b: CLCircularRegion) -> Bool {
        abs(a.radius - b.radius) < 1
            && abs(a.center.latitude - b.center.latitude) < 1e-6
            && abs(a.center.longitude - b.center.longitude) < 1e-6
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        // Catch the case where the user is already inside a workplace when monitoring starts.
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard state == .inside else { return }
        let id = region.identifier
        Task { @MainActor in ClockService.shared.handleEnter(regionIdentifier: id) }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let id = region.identifier
        Task { @MainActor in ClockService.shared.handleEnter(regionIdentifier: id) }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let id = region.identifier
        Task { @MainActor in ClockService.shared.handleExit(regionIdentifier: id) }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for \(region?.identifier ?? "?"): \(error)")
    }
}
