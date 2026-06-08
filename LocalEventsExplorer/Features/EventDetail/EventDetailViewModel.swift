import Combine
import MapKit

@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published private(set) var event: Event?
    @Published private(set) var isLoading = true

    private let repository: any EventRepository
    private let eventID: String

    init(repository: any EventRepository, eventID: String) {
        self.repository = repository
        self.eventID = eventID
    }

    func loadEvent() {
        Task {
            do {
                event = try await repository.event(id: eventID)
            } catch {
                event = nil
            }
            isLoading = false
        }
    }

    func toggleBookmark() {
        guard let event else { return }
        Task {
            do {
                try await repository.setBookmark(!event.isBookmarked, for: event)
                self.event = try await repository.event(id: eventID)
            } catch {
                // Keep current state
            }
        }
    }

    func openInMaps() {
        guard let event else { return }
        let coordinate = event.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.venueName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var formattedDistance: String? {
        guard let meters = event?.distanceMeters else { return nil }
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", meters / 1000)
    }

    var formattedDate: String {
        guard let date = event?.startTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
