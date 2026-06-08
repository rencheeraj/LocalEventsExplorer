import CoreData
import CoreLocation

protocol LocalEventDataSourceProtocol: Sendable {
    func cachedEvents() throws -> [Event]
    func upsertCachedEvents(_ dtos: [EventDTO]) throws
    func bookmarks() throws -> [Event]
    func setBookmark(_ bookmarked: Bool, for event: Event) throws
    func bookmarkedIDs() throws -> Set<String>
}

final class LocalEventDataSource: LocalEventDataSourceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func cachedEvents() throws -> [Event] {
        let request = CachedEventEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        let entities = try context.fetch(request)
        let bookmarkIDs = try bookmarkedIDs()
        return entities.compactMap { entity in
            mapToEvent(entity, isBookmarked: bookmarkIDs.contains(entity.id ?? ""))
        }
    }

    func upsertCachedEvents(_ dtos: [EventDTO]) throws {
        for dto in dtos {
            let request = CachedEventEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", dto.id)
            let existing = try context.fetch(request).first ?? CachedEventEntity(context: context)

            existing.id = dto.id
            existing.title = dto.title
            existing.eventDescription = dto.description
            existing.venueName = dto.venueName
            existing.latitude = dto.latitude
            existing.longitude = dto.longitude
            existing.startTime = dto.startTime
            existing.imageURL = dto.imageURL.absoluteString
            existing.fetchedAt = Date()
        }

        try context.save()
    }

    func bookmarks() throws -> [Event] {
        let request = BookmarkEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "bookmarkedAt", ascending: false)]
        let entities = try context.fetch(request)
        return entities.compactMap { mapBookmarkToEvent($0) }
    }

    func setBookmark(_ bookmarked: Bool, for event: Event) throws {
        if bookmarked {
            let request = BookmarkEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", event.id)
            if try context.fetch(request).first != nil {
                return
            }

            let entity = BookmarkEntity(context: context)
            entity.id = event.id
            entity.title = event.title
            entity.eventDescription = event.description
            entity.venueName = event.venueName
            entity.latitude = event.coordinate.latitude
            entity.longitude = event.coordinate.longitude
            entity.startTime = event.startTime
            entity.imageURL = event.imageURL.absoluteString
            entity.bookmarkedAt = Date()
        } else {
            let request = BookmarkEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", event.id)
            if let entity = try context.fetch(request).first {
                context.delete(entity)
            }
        }

        try context.save()
    }

    func bookmarkedIDs() throws -> Set<String> {
        let request = BookmarkEntity.fetchRequest()
        let entities = try context.fetch(request)
        return Set(entities.compactMap { $0.id })
    }

    // MARK: - Mapping

    private func mapToEvent(_ entity: CachedEventEntity, isBookmarked: Bool) -> Event? {
        guard let id = entity.id,
              let title = entity.title,
              let desc = entity.eventDescription,
              let venue = entity.venueName,
              let startTime = entity.startTime,
              let urlString = entity.imageURL,
              let url = URL(string: urlString) else {
            return nil
        }

        return Event(
            id: id,
            title: title,
            description: desc,
            venueName: venue,
            coordinate: .init(latitude: entity.latitude, longitude: entity.longitude),
            startTime: startTime,
            imageURL: url,
            isBookmarked: isBookmarked
        )
    }

    private func mapBookmarkToEvent(_ entity: BookmarkEntity) -> Event? {
        guard let id = entity.id,
              let title = entity.title,
              let desc = entity.eventDescription,
              let venue = entity.venueName,
              let startTime = entity.startTime,
              let urlString = entity.imageURL,
              let url = URL(string: urlString) else {
            return nil
        }

        return Event(
            id: id,
            title: title,
            description: desc,
            venueName: venue,
            coordinate: .init(latitude: entity.latitude, longitude: entity.longitude),
            startTime: startTime,
            imageURL: url,
            isBookmarked: true
        )
    }
}
