import Foundation

enum Endpoint {
    case events
    case event(id: String)

    var path: String {
        switch self {
        case .events:
            return "/events"
        case .event(let id):
            return "/events/\(id)"
        }
    }
}
