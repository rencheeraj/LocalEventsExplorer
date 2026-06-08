import Foundation
@testable import LocalEventsExplorer

final class MockAPIClient: APIClient, @unchecked Sendable {
    var result: Any?
    var error: Error?

    func get<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        if let error {
            throw error
        }
        guard let result = result as? T else {
            throw APIError.unknown("Mock not configured")
        }
        return result
    }
}
