import SwiftUI

struct EventListView: View {
    @StateObject var viewModel: EventListViewModel
    let repository: any EventRepository

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Events")
                .onAppear {
                    viewModel.loadEvents()
                }
                .toolbar {
                    if viewModel.isShowingCachedData {
                        ToolbarItem(placement: .bottomBar) {
                            cachedDataBanner
                        }
                    }
                }
                .refreshable {
                    viewModel.loadEvents(forceRefresh: true)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading events...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let events):
            List(events) { event in
                NavigationLink(value: event) {
                    EventRowView(event: event) {
                        viewModel.toggleBookmark(for: event)
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
                "No Events",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Check back later for events near you.")
            )

        case .error(let message):
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    private var cachedDataBanner: some View {
        Label("Showing cached data", systemImage: "wifi.slash")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let event: Event
    let onBookmarkTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: event.imageURL, maxPixel: 120)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(event.venueName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(event.startTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let distance = event.distanceMeters {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(formattedDistance(distance))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            Button(action: onBookmarkTap) {
                Image(systemName: event.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(event.isBookmarked ? .blue : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
