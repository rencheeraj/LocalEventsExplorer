# Architecture Diagram

```mermaid
graph TB
    subgraph Views["Views (SwiftUI)"]
        ELV[EventListView]
        EDV[EventDetailView]
        BV[BookmarksView]
    end

    subgraph ViewModels["ViewModels (@MainActor, ObservableObject)"]
        ELVM[EventListViewModel]
        EDVM[EventDetailViewModel]
        BVM[BookmarksViewModel]
    end

    subgraph Repository["Repository Layer"]
        ER[/"EventRepository (protocol)"/]
        ERI[EventRepositoryImpl]
    end

    subgraph DataSources["Data Sources"]
        RDS[/"RemoteEventDataSource (protocol)"/]
        RDSI[RemoteEventDataSourceImpl]
        LDS[/"LocalEventDataSource (protocol)"/]
        LDSI[LocalEventDataSourceImpl]
    end

    subgraph Core["Core Services"]
        API[URLSessionAPIClient]
        RC[ResponseCache<br/>actor, TTL 300s]
        IC[ImageCache<br/>NSCache + Disk + Downsample]
        LS[LocationService<br/>CLLocationManager + Combine]
        BRS[BackgroundRefreshService<br/>BGAppRefreshTask]
        PC[PersistenceController<br/>Core Data Stack]
    end

    subgraph External["External"]
        MockAPI[(Mock API<br/>localhost:3001)]
        CD[(Core Data<br/>CachedEventEntity<br/>BookmarkEntity)]
        Disk[(Disk Cache<br/>Images)]
    end

    subgraph DI["Composition Root"]
        AD[AppDependencies]
    end

    ELV --> ELVM
    EDV --> EDVM
    BV --> BVM

    ELVM --> ER
    EDVM --> ER
    BVM --> ER

    ER -.-> ERI
    ERI --> RDS
    ERI --> LDS

    RDS -.-> RDSI
    LDS -.-> LDSI

    RDSI --> API
    RDSI --> RC
    LDSI --> PC

    API --> MockAPI
    PC --> CD
    IC --> Disk

    ELVM --> LS
    EDVM --> LS
    BRS --> ER

    AD -->|creates & injects| ELVM
    AD -->|creates & injects| EDVM
    AD -->|creates & injects| BVM

    style Views fill:#e1f5fe
    style ViewModels fill:#fff3e0
    style Repository fill:#e8f5e9
    style DataSources fill:#fce4ec
    style Core fill:#f3e5f5
    style External fill:#f5f5f5
    style DI fill:#fff9c4
```

## Data Flow

```mermaid
graph LR
    API_JSON["API JSON"] -->|decode| DTO["EventDTO<br/>(Codable)"]
    DTO -->|map in Repository| DM["Event<br/>(Domain Model)"]
    DM -->|@Published| VM["ViewModel<br/>(ViewState)"]
    VM -->|binding| V["SwiftUI View"]

    CD_Entity["Core Data Entity"] -->|map in DataSource| DM

    style DTO fill:#fce4ec
    style DM fill:#e8f5e9
    style VM fill:#fff3e0
    style V fill:#e1f5fe
    style CD_Entity fill:#f5f5f5
```
