import SwiftUI

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let event = viewModel.event {
                eventContent(event)
            } else {
                ContentUnavailableView(
                    "Event Not Found",
                    systemImage: "magnifyingglass",
                    description: Text("This event may no longer be available.")
                )
            }
        }
        .onAppear {
            viewModel.loadEvent()
        }
    }

    @ViewBuilder
    private func eventContent(_ event: Event) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CachedAsyncImage(url: event.imageURL)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    eventHeader(event)
                    Divider()
                    Text(event.description)
                        .font(.body)
                    actionButtons(event)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func eventHeader(_ event: Event) -> some View {
        Text(event.title)
            .font(.title2)
            .fontWeight(.bold)

        HStack {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.secondary)
            Text(event.venueName)
                .foregroundStyle(.secondary)
        }

        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            Text(viewModel.formattedDate)
                .foregroundStyle(.secondary)
        }

        if let distance = viewModel.formattedDistance {
            HStack {
                Image(systemName: "location")
                    .foregroundStyle(.secondary)
                Text(distance)
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(_ event: Event) -> some View {
        HStack(spacing: 16) {
            Button {
                viewModel.toggleBookmark()
            } label: {
                Label(
                    event.isBookmarked ? "Bookmarked" : "Bookmark",
                    systemImage: event.isBookmarked ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(event.isBookmarked ? .blue : .gray)

            Button {
                viewModel.openInMaps()
            } label: {
                Label("Directions", systemImage: "map")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 8)
    }
}
