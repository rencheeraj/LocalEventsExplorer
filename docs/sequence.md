# Sequence Diagrams

## 1. Event List Load (Online - Happy Path)

```mermaid
sequenceDiagram
    participant V as EventListView
    participant VM as EventListViewModel
    participant R as EventRepository
    participant RDS as RemoteEventDataSource
    participant RC as ResponseCache
    participant API as APIClient
    participant LDS as LocalEventDataSource
    participant CD as Core Data

    V->>VM: .onAppear / pull-to-refresh
    VM->>VM: state = .loading
    VM->>R: events(forceRefresh:)

    R->>RDS: fetchEvents()
    RDS->>RC: value(forKey: "/events")
    RC-->>RDS: nil (miss or expired)
    RDS->>API: get(.events)
    API-->>RDS: [EventDTO]
    RDS->>RC: setValue(data, forKey: "/events")
    RDS-->>R: [EventDTO]

    R->>R: map DTO -> [Event]
    R->>LDS: upsertCachedEvents([Event])
    LDS->>CD: batch upsert CachedEventEntity
    R->>LDS: bookmarkedIDs()
    LDS->>CD: fetch BookmarkEntity IDs
    LDS-->>R: Set<String>
    R->>R: merge isBookmarked flags
    R-->>VM: [Event]

    VM->>VM: state = .loaded([Event])
    V->>V: re-render list
```

## 2. Event List Load (Offline - Cache Fallback)

```mermaid
sequenceDiagram
    participant V as EventListView
    participant VM as EventListViewModel
    participant R as EventRepository
    participant RDS as RemoteEventDataSource
    participant LDS as LocalEventDataSource
    participant CD as Core Data

    V->>VM: .onAppear / pull-to-refresh
    VM->>VM: state = .loading
    VM->>R: events(forceRefresh:)

    R->>RDS: fetchEvents()
    RDS--xR: throws APIError.network

    R->>LDS: fetchCachedEvents()
    LDS->>CD: fetch CachedEventEntity
    CD-->>LDS: [CachedEventEntity]
    LDS-->>R: [Event]

    R->>LDS: bookmarkedIDs()
    LDS-->>R: Set<String>
    R->>R: merge isBookmarked flags
    R-->>VM: [Event] + isShowingCachedData = true

    VM->>VM: state = .loaded([Event])
    VM->>VM: isShowingCachedData = true
    V->>V: show "Showing cached data" banner
```

## 3. Bookmark Toggle

```mermaid
sequenceDiagram
    participant V as EventDetailView
    participant VM as EventDetailViewModel
    participant R as EventRepository
    participant LDS as LocalEventDataSource
    participant CD as Core Data

    V->>VM: toggleBookmark()
    VM->>R: setBookmark(true, for: event)
    R->>LDS: addBookmark(event)
    LDS->>CD: upsert BookmarkEntity
    CD-->>LDS: success
    LDS-->>R: success
    R-->>VM: success
    VM->>VM: event.isBookmarked = true
    V->>V: update bookmark icon (filled)
```

## 4. Image Loading (CachedAsyncImage)

```mermaid
sequenceDiagram
    participant V as CachedAsyncImage
    participant IC as ImageCache
    participant Mem as NSCache (Memory)
    participant Disk as FileManager (Disk)
    participant Net as URLSession

    V->>IC: image(for: url, maxPixel: 300)

    IC->>Mem: lookup(url)
    alt Memory Hit
        Mem-->>IC: UIImage
        IC-->>V: UIImage
    else Memory Miss
        IC->>Disk: lookup(hash(url))
        alt Disk Hit
            Disk-->>IC: Data
            IC->>IC: downsample(data, maxPixel)
            IC->>Mem: store(url, image)
            IC-->>V: UIImage
        else Disk Miss
            IC->>Net: data(from: url)
            Net-->>IC: Data
            IC->>Disk: write(hash(url), data)
            IC->>IC: downsample(data, maxPixel)
            IC->>Mem: store(url, image)
            IC-->>V: UIImage
        end
    end
```

## 5. Background Refresh

```mermaid
sequenceDiagram
    participant OS as iOS System
    participant BRS as BackgroundRefreshService
    participant R as EventRepository
    participant RDS as RemoteEventDataSource
    participant LDS as LocalEventDataSource

    OS->>BRS: handleAppRefresh(task:)
    BRS->>BRS: set expirationHandler
    BRS->>R: events(forceRefresh: true)
    R->>RDS: fetchEvents()
    RDS-->>R: [EventDTO]
    R->>LDS: upsertCachedEvents()
    R-->>BRS: [Event]
    BRS->>BRS: scheduleNextRefresh(30 min)
    BRS->>OS: task.setTaskCompleted(success: true)
```
