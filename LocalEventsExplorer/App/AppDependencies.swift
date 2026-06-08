import Foundation

@MainActor
final class AppDependencies {
    let persistenceController: PersistenceController
    let apiClient: any APIClient
    let responseCache: ResponseCache
    let locationService: any LocationServiceProtocol
    let remoteDataSource: any RemoteEventDataSourceProtocol
    let localDataSource: any LocalEventDataSourceProtocol
    let repository: any EventRepository
    let backgroundRefreshService: BackgroundRefreshService

    init() {
        persistenceController = PersistenceController()
        apiClient = URLSessionAPIClient()
        responseCache = ResponseCache()
        locationService = LocationService()

        remoteDataSource = RemoteEventDataSource(
            apiClient: apiClient,
            responseCache: responseCache
        )

        localDataSource = LocalEventDataSource(
            context: persistenceController.viewContext
        )

        repository = EventRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            locationService: locationService
        )

        backgroundRefreshService = BackgroundRefreshService(
            repository: repository
        )
    }
}
