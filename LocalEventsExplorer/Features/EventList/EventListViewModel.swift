import Combine
import Foundation

enum ViewState: Equatable {
    case loading
    case loaded([Event])
    case empty
    case error(String)
}

@MainActor
final class EventListViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .loading
    @Published var isShowingCachedData = false

    private let repository: any EventRepository
    private var loadTask: Task<Void, Never>?

    init(repository: any EventRepository) {
        self.repository = repository
    }

    func loadEvents(forceRefresh: Bool = false) {
        loadTask?.cancel()
        loadTask = Task {
            if !forceRefresh {
                state = .loading
            }

            do {
                let result = try await repository.events(forceRefresh: forceRefresh)
                guard !Task.isCancelled else { return }
                isShowingCachedData = result.isCachedData
                if result.events.isEmpty {
                    state = .empty
                } else {
                    let sorted = result.events.sorted { lhs, rhs in
                        if let ld = lhs.distanceMeters, let rd = rhs.distanceMeters {
                            return ld < rd
                        }
                        return lhs.startTime < rhs.startTime
                    }
                    state = .loaded(sorted)
                }
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(error.localizedDescription)
            }
        }
    }

    func toggleBookmark(for event: Event) {
        Task {
            do {
                try await repository.setBookmark(!event.isBookmarked, for: event)
                loadEvents(forceRefresh: false)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
