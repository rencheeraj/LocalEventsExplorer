import Combine
import CoreLocation

protocol LocationServiceProtocol: Sendable {
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var currentLocation: CLLocation? { get }
    func requestPermission()
    func startUpdating()
    func stopUpdating()
}

final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    nonisolated var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    nonisolated var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }

    nonisolated var currentLocation: CLLocation? {
        locationSubject.value
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationSubject.send(manager.authorizationStatus)
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        locationSubject.send(locations.last)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubject.send(manager.authorizationStatus)
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}
