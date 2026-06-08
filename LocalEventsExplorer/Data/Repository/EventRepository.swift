protocol EventRepository: Sendable {
    func events(forceRefresh: Bool) async throws -> EventsResult
    func event(id: String) async throws -> Event?
    func bookmarks() async throws -> [Event]
    func setBookmark(_ bookmarked: Bool, for event: Event) async throws
}

struct EventsResult: Sendable {
    let events: [Event]
    let isCachedData: Bool
}
