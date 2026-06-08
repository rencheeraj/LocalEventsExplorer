@testable import LocalEventsExplorer
import XCTest

final class EventRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var mockAPI: MockAPIClient!
    private var mockLocation: MockLocationService!
    private var repository: EventRepositoryImpl!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        mockAPI = MockAPIClient()
        mockLocation = MockLocationService()

        let responseCache = ResponseCache(ttl: 0)
        let remoteDataSource = RemoteEventDataSource(
            apiClient: mockAPI,
            responseCache: responseCache
        )
        let localDataSource = LocalEventDataSource(
            context: persistence.viewContext
        )

        repository = EventRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            locationService: mockLocation
        )
    }

    override func tearDown() {
        persistence = nil
        mockAPI = nil
        mockLocation = nil
        repository = nil
        super.tearDown()
    }

    @MainActor
    func testOfflineFallbackReturnsCachedEvents() async throws {
        let dto = makeTestDTO()
        mockAPI.result = [dto] as [EventDTO]

        // First call: fetch from network, populates cache
        let firstResult = try await repository.events(forceRefresh: false)
        XCTAssertEqual(firstResult.events.count, 1)
        XCTAssertFalse(firstResult.isCachedData)

        // Simulate network failure
        mockAPI.error = APIError.network(URLError(.notConnectedToInternet))
        mockAPI.result = nil

        // Second call: should fallback to cached data
        let secondResult = try await repository.events(forceRefresh: true)
        XCTAssertEqual(secondResult.events.count, 1)
        XCTAssertTrue(secondResult.isCachedData)
        XCTAssertEqual(secondResult.events.first?.title, "Test Event")
    }

    @MainActor
    func testNetworkFailureWithEmptyCacheThrows() async {
        mockAPI.error = APIError.network(URLError(.notConnectedToInternet))

        do {
            _ = try await repository.events(forceRefresh: false)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    private func makeTestDTO() -> EventDTO {
        EventDTO(
            id: "1",
            title: "Test Event",
            description: "A test event",
            venueName: "Test Venue",
            latitude: 42.98,
            longitude: -81.24,
            startTime: Date(),
            imageURL: URL(string: "https://example.com/image.jpg")!
        )
    }
}
