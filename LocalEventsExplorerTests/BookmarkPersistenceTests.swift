import CoreLocation
@testable import LocalEventsExplorer
import XCTest

final class BookmarkPersistenceTests: XCTestCase {
    private var persistence: PersistenceController!
    private var dataSource: LocalEventDataSource!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        dataSource = LocalEventDataSource(context: persistence.viewContext)
    }

    override func tearDown() {
        persistence = nil
        dataSource = nil
        super.tearDown()
    }

    @MainActor
    func testBookmarkEventAndRetrieve() throws {
        let event = makeTestEvent(id: "1")

        try dataSource.setBookmark(true, for: event)
        let bookmarks = try dataSource.bookmarks()

        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.id, "1")
        XCTAssertEqual(bookmarks.first?.title, "Test Event")
        XCTAssertTrue(bookmarks.first?.isBookmarked ?? false)
    }

    @MainActor
    func testRemoveBookmark() throws {
        let event = makeTestEvent(id: "2")

        try dataSource.setBookmark(true, for: event)
        XCTAssertEqual(try dataSource.bookmarks().count, 1)

        try dataSource.setBookmark(false, for: event)
        XCTAssertEqual(try dataSource.bookmarks().count, 0)
    }

    @MainActor
    func testBookmarkIdempotency() throws {
        let event = makeTestEvent(id: "3")

        try dataSource.setBookmark(true, for: event)
        try dataSource.setBookmark(true, for: event)

        XCTAssertEqual(try dataSource.bookmarks().count, 1)
    }

    @MainActor
    func testBookmarkedIDsMergeWithCache() throws {
        let event = makeTestEvent(id: "4")
        try dataSource.setBookmark(true, for: event)

        let ids = try dataSource.bookmarkedIDs()
        XCTAssertTrue(ids.contains("4"))
    }

    private func makeTestEvent(id: String) -> Event {
        Event(
            id: id,
            title: "Test Event",
            description: "Description",
            venueName: "Venue",
            coordinate: CLLocationCoordinate2D(latitude: 42.98, longitude: -81.24),
            startTime: Date(),
            imageURL: URL(string: "https://example.com/img.jpg")!,
            isBookmarked: false
        )
    }
}
