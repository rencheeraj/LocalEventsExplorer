import CoreLocation

struct Event: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let venueName: String
    let coordinate: CLLocationCoordinate2D
    let startTime: Date
    let imageURL: URL
    var isBookmarked: Bool
    var distanceMeters: Double?

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.description == rhs.description
            && lhs.venueName == rhs.venueName
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.startTime == rhs.startTime
            && lhs.imageURL == rhs.imageURL
            && lhs.isBookmarked == rhs.isBookmarked
            && lhs.distanceMeters == rhs.distanceMeters
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
