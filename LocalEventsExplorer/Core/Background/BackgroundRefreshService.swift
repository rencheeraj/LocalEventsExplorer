import BackgroundTasks

final class BackgroundRefreshService: Sendable {
    static let taskIdentifier = "com.rencheeraj.LocalEventsExplorer.refresh"

    private let repository: any EventRepository

    init(repository: any EventRepository) {
        self.repository = repository
    }

    func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleRefresh(task: task)
        }
    }

    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleRefresh()

        let refreshTask = Task {
            _ = try? await repository.events(forceRefresh: true)
        }

        task.expirationHandler = {
            refreshTask.cancel()
        }

        Task {
            _ = await refreshTask.result
            task.setTaskCompleted(success: true)
        }
    }
}
