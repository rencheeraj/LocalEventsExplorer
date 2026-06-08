import Combine
import CoreLocation
@testable import LocalEventsExplorer

final class MockLocationService: LocationServiceProtocol, @unchecked Sendable {
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let authSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.authorizedWhenInUse)

    nonisolated var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    nonisolated var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authSubject.eraseToAnyPublisher()
    }

    nonisolated var currentLocation: CLLocation? {
        locationSubject.value
    }

    var mockLocation: CLLocation? {
        didSet { locationSubject.send(mockLocation) }
    }

    func requestPermission() {}
    func startUpdating() {}
    func stopUpdating() {}
}
