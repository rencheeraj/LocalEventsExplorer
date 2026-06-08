# Engineering Standards

## Architecture Layering

```
View -> ViewModel -> Repository -> DataSource
```

No layer may skip another. Views never access DataSources or the network directly.

## Data Flow

- **DTO** (`EventDTO`): Codable struct matching the API JSON. Never leaks past the Repository layer.
- **Domain Model** (`Event`): What the UI consumes. Mapped from DTO in the Repository.
- **Core Data Entities** (`CachedEventEntity`, `BookmarkEntity`): Persistence layer only. Mapped to/from domain models in `LocalEventDataSource`.

## Dependency Injection

- All dependencies are behind protocols.
- Concrete implementations are built only at the app root (`AppDependencies`).
- ViewModels receive dependencies via initializer injection.
- Tests use mock implementations conforming to the same protocols.

## Concurrency

- ViewModels are `@MainActor` and use `ObservableObject` + `@Published`.
- All I/O uses `async/await`.
- `ResponseCache` is an `actor` for thread-safe access.
- Background work uses `Task {}` with cancellation support.

## Error Handling

- Errors are typed enums (`APIError`).
- No force-unwraps in production code.
- Network failures gracefully fall back to cached data.
- ViewModels surface errors via `ViewState.error(String)`.

## Code Style

- SwiftLint enforced (see `.swiftlint.yml`).
- Files should be under ~200 lines.
- One feature per folder under `Features/`.
- Conventional commits: `feat:`, `fix:`, `chore:`, `test:`, `docs:`.

## Testing

- Unit tests use in-memory Core Data (`PersistenceController(inMemory: true)`).
- Network calls are mocked via `MockAPIClient`.
- Location is mocked via `MockLocationService`.
- Three required test suites:
  1. `ResponseCacheTests` - TTL behavior
  2. `EventRepositoryTests` - Offline fallback
  3. `BookmarkPersistenceTests` - Bookmark CRUD
