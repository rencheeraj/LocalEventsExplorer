import Foundation

struct EventDTO: @preconcurrency Codable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let venueName: String
    let latitude: Double
    let longitude: Double
    let startTime: Date
    let imageURL: URL

    enum CodingKeys: String, CodingKey {
        case id, title, description, venueName, latitude, longitude, startTime
        case imageURL = "imageUrl"
    }
}
