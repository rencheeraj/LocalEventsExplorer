import Combine
import CoreLocation

final class EventRepositoryImpl: EventRepository {
    private let remoteDataSource: any RemoteEventDataSourceProtocol
    private let localDataSource: any LocalEventDataSourceProtocol
    private let locationService: any LocationServiceProtocol

    init(
        remoteDataSource: any RemoteEventDataSourceProtocol,
        localDataSource: any LocalEventDataSourceProtocol,
        locationService: any LocationServiceProtocol
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.locationService = locationService
    }

    func events(forceRefresh: Bool) async throws -> EventsResult {
        do {
            let dtos = try await remoteDataSource.fetchEvents()
            try localDataSource.upsertCachedEvents(dtos)
            let events = try localDataSource.cachedEvents()
            return EventsResult(
                events: attachDistances(to: events),
                isCachedData: false
            )
        } catch {
            let cached = try localDataSource.cachedEvents()
            if cached.isEmpty {
                throw error
            }
            return EventsResult(
                events: attachDistances(to: cached),
                isCachedData: true
            )
        }
    }

    func event(id: String) async throws -> Event? {
        let result = try await events(forceRefresh: false)
        return result.events.first { $0.id == id }
    }

    func bookmarks() async throws -> [Event] {
        let events = try localDataSource.bookmarks()
        return attachDistances(to: events)
    }

    func setBookmark(_ bookmarked: Bool, for event: Event) async throws {
        try localDataSource.setBookmark(bookmarked, for: event)
    }

    private func attachDistances(to events: [Event]) -> [Event] {
        var userLocation: CLLocation?
        let semaphore = DispatchSemaphore(value: 0)
        var cancellable: (any Sendable)?

        cancellable = locationService.locationPublisher
            .first()
            .sink { location in
                userLocation = location
                semaphore.signal()
                _ = cancellable
            }

        semaphore.wait()

        guard let location = userLocation else { return events }

        return events.map { event in
            var updated = event
            let eventLocation = CLLocation(
                latitude: event.coordinate.latitude,
                longitude: event.coordinate.longitude
            )
            updated.distanceMeters = location.distance(from: eventLocation)
            return updated
        }
    }
}
