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
            if case .loading = state {
                // Keep loading state only on initial load
            } else if case .error = state {
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
                let newValue = !event.isBookmarked
                try await repository.setBookmark(newValue, for: event)
                // Optimistically update the current list immediately
                if case .loaded(let events) = state {
                    let updated = events.map { existing in
                        guard existing.id == event.id else { return existing }
                        var copy = existing
                        copy.isBookmarked = newValue
                        return copy
                    }
                    state = .loaded(updated)
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
