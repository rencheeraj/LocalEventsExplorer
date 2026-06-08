import Foundation

protocol RemoteEventDataSourceProtocol: Sendable {
    func fetchEvents() async throws -> [EventDTO]
    func fetchEvent(id: String) async throws -> EventDTO
}

final class RemoteEventDataSource: RemoteEventDataSourceProtocol {
    private let apiClient: any APIClient
    private let responseCache: ResponseCache
    private let decoder: JSONDecoder

    init(apiClient: any APIClient, responseCache: ResponseCache) {
        self.apiClient = apiClient
        self.responseCache = responseCache

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchEvents() async throws -> [EventDTO] {
        let cacheKey = Endpoint.events.path

        if let cached = await responseCache.value(forKey: cacheKey) {
            if let events = try? decoder.decode([EventDTO].self, from: cached) {
                return events
            }
        }

        let events: [EventDTO] = try await apiClient.get(.events)

        if let data = try? JSONEncoder().encode(events) {
            await responseCache.setValue(data, forKey: cacheKey)
        }

        return events
    }

    func fetchEvent(id: String) async throws -> EventDTO {
        try await apiClient.get(.event(id: id))
    }
}
