import Combine
import Foundation

@MainActor
final class BookmarksViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .loading

    private let repository: any EventRepository

    init(repository: any EventRepository) {
        self.repository = repository
    }

    func loadBookmarks() {
        Task {
            do {
                let bookmarks = try await repository.bookmarks()
                if bookmarks.isEmpty {
                    state = .empty
                } else {
                    state = .loaded(bookmarks)
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func removeBookmark(for event: Event) {
        Task {
            do {
                try await repository.setBookmark(false, for: event)
                loadBookmarks()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
