import SwiftUI

@main
struct LocalEventsExplorerApp: App {
    @State private var deps = AppDependencies()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Events", systemImage: "calendar") {
                    EventListView(
                        viewModel: EventListViewModel(repository: deps.repository),
                        repository: deps.repository
                    )
                }

                Tab("Bookmarks", systemImage: "bookmark") {
                    BookmarksView(
                        viewModel: BookmarksViewModel(repository: deps.repository),
                        repository: deps.repository
                    )
                }
            }
            .onAppear {
                deps.locationService.requestPermission()
                deps.backgroundRefreshService.registerTask()
                deps.backgroundRefreshService.scheduleRefresh()
            }
        }
    }
}
