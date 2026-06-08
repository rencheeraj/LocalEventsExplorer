import Foundation

enum APIError: Error, Equatable {
    case network(URLError)
    case decoding(String)
    case server(status: Int)
    case unknown(String)
}

protocol APIClient: Sendable {
    func get<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
}

final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(
        baseURL: URL = URL(string: "http://localhost:3001")!,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 15
            self.session = URLSession(configuration: config)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func get<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint.path)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(status: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }
}
