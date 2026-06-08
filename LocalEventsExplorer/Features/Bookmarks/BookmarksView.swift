import SwiftUI

struct BookmarksView: View {
    @StateObject var viewModel: BookmarksViewModel
    let repository: any EventRepository

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmarks")
                .onAppear {
                    viewModel.loadBookmarks()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let events):
            List(events) { event in
                NavigationLink(value: event) {
                    EventRowView(event: event) {
                        viewModel.removeBookmark(for: event)
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Event.self) { event in
                EventDetailView(
                    viewModel: EventDetailViewModel(
                        repository: repository,
                        eventID: event.id
                    )
                )
            }

        case .empty:
            ContentUnavailableView(
                "No Bookmarks",
                systemImage: "bookmark",
                description: Text("Bookmark events to save them for later.")
            )

        case .error(let message):
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}
