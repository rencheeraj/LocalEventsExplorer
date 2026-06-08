# Local Events Explorer

A native iOS app that displays nearby events, lets users bookmark them, shows distances, and works offline with cached data. Built with SwiftUI, Combine, Core Data, and MVVM architecture.

## Getting Started

### Prerequisites

- Xcode 26+
- Node.js 18+ (for mock API)
- SwiftLint (`brew install swiftlint`)

### 1. Start the Mock API

```bash
cd mock-api
npm install
node seed.js
npm start
```

The API runs at `http://localhost:3001`. Endpoints: `GET /events`, `GET /events/:id`.

### 2. Run the App

Open `LocalEventsExplorer.xcodeproj` in Xcode, select an iOS Simulator, and run.

> **Note:** The app connects to `localhost:3001` by default. For on-device testing, use `ngrok` to tunnel the mock API and update the base URL in `URLSessionAPIClient`.

## Architecture

```
View -> ViewModel -> Repository -> DataSource -> (API / Core Data)
```

**MVVM + Repository** with protocol-oriented design and constructor injection.

See [Architecture Diagram](docs/architecture.md) and [Sequence Diagrams](docs/sequence.md) for visual references.

- **Views** (SwiftUI): Declarative UI bound to ViewModels via `@StateObject`.
- **ViewModels**: `@MainActor ObservableObject` exposing `@Published` state. Depend only on protocols.
- **Repository** (`EventRepository`): Single source of truth. Network-first with Core Data fallback.
- **DataSources**: `RemoteEventDataSource` (API + in-memory response cache) and `LocalEventDataSource` (Core Data CRUD).
- **DI**: `AppDependencies` at the app root builds all concretes and injects via initializers.

### Key Files

| File | Purpose |
|------|---------|
| `App/AppDependencies.swift` | Composition root - wires all dependencies |
| `Data/Repository/EventRepositoryImpl.swift` | Network-first + cache fallback logic |
| `Core/Cache/ResponseCache.swift` | Actor-based in-memory TTL cache |
| `Core/Cache/ImageCache.swift` | NSCache + disk + downsampling |
| `Core/Location/LocationService.swift` | CLLocationManager Combine wrapper |

## Trade-offs

| Decision | Rationale |
|----------|-----------|
| **Core Data over SwiftData** | Mature, fine-grained upsert control, in-memory store for tests. SwiftData is newer but less battle-tested for cache patterns. |
| **async/await + Combine** | async/await for I/O (cleaner than callback chains), Combine for reactive location publishing to the UI. |
| **Network-first + cache fallback** | Users get fresh data when online; graceful degradation offline. Simpler than sync-first approaches. |
| **Hand-rolled ImageCache** | Demonstrates ImageIO downsampling, NSCache + disk caching without third-party dependencies. Shows resource management skills. |
| **DTO != Domain Model** | Clean separation prevents API changes from leaking into the UI. Repository maps between layers. |
| **No LWW / conflict resolution** | Single-device app with read-mostly data. Bookmarks are local-only, no sync conflicts possible. |

## Resource Usage

- **Thumbnail downsampling**: `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` so full-resolution images never load into memory.
- **Lazy List**: SwiftUI `List` lazily loads rows, keeping memory footprint low.
- **NSCache eviction**: Memory cache has a `countLimit`; OS can evict under pressure.
- **Low-frequency background refresh**: `BGAppRefreshTask` scheduled every 30 minutes (OS-discretionary).

## Testing Background Refresh

Background refresh is OS-discretionary. To test in the Simulator:

1. Run the app, then pause in the debugger
2. Execute in the LLDB console:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.rencheeraj.LocalEventsExplorer.refresh"]
```
3. Resume execution

## Running Tests & Lint

```bash
# Run all tests
xcodebuild -project LocalEventsExplorer.xcodeproj \
  -scheme LocalEventsExplorer \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test

# Run SwiftLint
swiftlint
```

## License

This project is for assessment purposes.
