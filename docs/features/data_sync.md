# Feature: Data Synchronisation

## Summary

The Data Sync feature provides **bidirectional, offline-first synchronisation** between the Flutter app's local SQLite database and the backend MySQL database. The backend exposes a read-only **`SyncController`** (4 GET endpoints under `api/Sync`) that returns changes since a given timestamp. The Flutter client orchestrates sync through a **`SyncService`** (1,009 LOC) that compares local vs. remote timestamps, downloads changed artefacts/categories/boards (including binary assets), and uploads local-only items. A **`SyncTimer`** singleton fires every 30 seconds by default, triggering `SyncService.autoSync()`. Per-entity-type metadata is tracked in a local `sync_metadata` SQLite table via **`SyncMetadataRepository`**. A separate **`RemoteSyncService`** handles real-time board collaboration over SignalR (documented in [Real-time Collaboration](realtime_collaboration.md)); it is _not_ part of the polling-based data sync described here.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class SyncController {
            +GetChanges(since: DateTime) ActionResult~SyncResponseDTO~
            +GetChangedArtefacts(since: DateTime) ActionResult~List~FileChangeDTO~~
            +GetChangedBoards(since: DateTime) ActionResult~List~FileChangeDTO~~
            +GetChangeSummary(since: DateTime) ActionResult~SyncSummaryDTO~
        }
        class FileChangeDTO {
            +FileId: string
            +FileName: string
            +FileType: string
            +ModifiedDate: DateTime?
            +ImageUrl: string?
            +SoundUrl: string?
        }
        class SyncResponseDTO {
            +ChangedFiles: List~FileChangeDTO~
            +CheckDate: DateTime
            +TotalChanges: int
        }
        class SyncSummaryDTO {
            +TotalChanges: int
            +ArtefactChanges: int
            +BoardChanges: int
            +CheckDate: DateTime
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class SyncService {
            +checkForChanges(since: DateTime) Future~SyncCheckResponse?~
            +checkLocalChanges(since: DateTime) Future~SyncCheckResponse?~
            +syncFromServer() Future~bool~
            +getChangesByType(since: DateTime) Future~Map?~
            +getChangeSummary(since: DateTime) Future~Map?~
            +hasChanges(since: DateTime) Future~bool~
            +getLastSyncDate() Future~DateTime?~
            +setLastSyncDate(date: DateTime) Future~void~
            +needsSync(threshold: Duration) Future~bool~
            +autoSync(threshold: Duration) Future~bool~
            +getLocalItemCounts() Future~Map~
        }
        class SyncTimer {
            +start(interval: Duration) void
            +stop() void
            +syncNow() Future~void~
            +isRunning: bool
            +syncService: SyncService
            +getStatus() String
        }
        class SyncMetadataRepository {
            +upsert(metadata: SyncMetadataDB) Future~int~
            +get(userId, entityType) Future~SyncMetadataDB?~
            +getAll(userId) Future~List~
            +getLastSyncDate(userId, entityType) Future~DateTime?~
            +updateLastSyncDate(userId, entityType, date) Future~void~
            +updateLastCheckDate(userId, entityType) Future~void~
            +delete(userId, entityType) Future~int~
            +deleteAllForUser(userId) Future~int~
            +deleteAll() Future~int~
        }
        class SyncMetadataDB {
            +id: int?
            +userId: String
            +entityType: String
            +lastSyncDate: int
            +lastCheckDate: int
        }
        class FileChangeRecord {
            +fileId: String
            +fileName: String
            +fileType: String
            +modifiedDate: DateTime?
            +imageUrl: String?
            +soundUrl: String?
            +fromJson() FileChangeRecord
            +fromArtefact() FileChangeRecord
            +fromBoard() FileChangeRecord
        }
        class RemoteSyncService {
            +start(sessionId, onRemoteUpdate) Future~void~
            +sendUpdate(update: BoardUpdate) Future~void~
            +stop() Future~void~
        }
    }

    %% ── Relationships ────────────────────────────
    SyncTimer --> SyncService : fires every 30s
    SyncService --> SyncMetadataRepository : tracks sync timestamps
    SyncService ..> SyncController : HTTP GET
    SyncService --> FileChangeRecord : parses responses
    SyncMetadataRepository --> SyncMetadataDB : persists
    SyncController --> FileChangeDTO : returns
    SyncController --> SyncResponseDTO : returns
    SyncController --> SyncSummaryDTO : returns
```

---

## Sequence Diagram — Periodic Sync Cycle

```mermaid
sequenceDiagram
    participant Timer as SyncTimer (30s)
    participant SS as SyncService
    participant Meta as SyncMetadataRepository
    participant API as SyncController (Backend)
    participant DB as Local SQLite
    participant Files as Local Filesystem

    Timer->>SS: autoSync(threshold: Duration.zero)
    SS->>Meta: needsSync() → getLastSyncDate()
    Meta-->>SS: lastSyncDate

    alt Sync needed
        SS->>SS: syncFromServer()

        %% Download phase
        SS->>API: GET /Sync/changes?since={lastSync}
        API-->>SS: SyncResponseDTO {changedFiles, checkDate}

        loop Each FileChangeRecord
            SS->>SS: _decideSyncDirection(local.modifiedDate, remote.modifiedDate)
            alt Download (remote newer)
                alt artefact
                    SS->>API: GET /Artefacts/{id}
                    API-->>SS: Artefact JSON + asset URLs
                    SS->>Files: _downloadAsset(imageUrl → Synced/)
                    SS->>Files: _downloadAsset(soundUrl → Synced/)
                    SS->>DB: ArtefactRepository.insert(artefactDB)
                end
                alt board
                    SS->>API: GET /Boards/{id}
                    API-->>SS: Board JSON + savedArtefacts
                    SS->>DB: SavedBoardRepository.insert(boardDB)
                    loop Each savedArtefact
                        SS->>DB: SavedArtefactRepository.insert()
                    end
                end
            else Upload (local only)
                SS->>API: POST /Artefacts (multipart)
                SS->>API: POST /Boards (JSON)
            else Skip (same timestamp)
                Note right of SS: No action
            end
        end

        SS->>Meta: updateLastSyncDate(userId, 'all', now)
        SS-->>Timer: true (success)
    else Sync not needed
        SS-->>Timer: false
    end
```

---

## Sequence Diagram — Check-Only (Summary)

```mermaid
sequenceDiagram
    participant Client as Flutter Widget
    participant SS as SyncService
    participant API as SyncController

    Client->>SS: getChangeSummary(since)
    SS->>API: GET /Sync/summary?since={iso8601}
    API->>API: COUNT artefacts WHERE modifiedDate > since
    API->>API: COUNT boards WHERE modifiedDate > since
    API-->>SS: SyncSummaryDTO {total, artefacts, boards}
    SS-->>Client: {total, artefacts, boards}
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **`SyncService` is a god class** | 🔴 Critical | 1,009 lines handling API calls, file I/O, database operations, conflict resolution, and asset downloading. Split into `SyncDownloader`, `SyncUploader`, `SyncConflictResolver`, `AssetManager`. |
| 2 | **No transaction safety** | 🔴 Critical | A partial sync failure (e.g., crash mid-download) leaves the local DB in an inconsistent state. No rollback mechanism exists. Wrap each entity sync in a DB transaction. |
| 3 | **~40 `Console.WriteLine` debug statements** in SyncController | 🟠 High | Production backend logs every single sync request with verbose debug output. Replace with `ILogger` and use appropriate log levels. |
| 4 | **30-second timer with no backoff** | 🟠 High | `SyncTimer` fires every 30s with no exponential backoff on failure and no connectivity check. Will hammer the server when offline or on errors. |
| 5 | **No retry logic** | 🟠 High | Failed asset downloads or uploads are silently ignored. No retry queue or dead-letter mechanism. |
| 6 | **No pagination on sync endpoints** | 🟡 Medium | `GetChanges` returns ALL changes since timestamp in one response. Large change sets will cause memory pressure and slow responses. Add cursor-based pagination. |
| 7 | **Last-write-wins conflict resolution** | 🟡 Medium | `_decideSyncDirection` simply compares Unix timestamps. No merge strategy for concurrent edits from different devices. |
| 8 | **`FileType` is a raw string** | 🟡 Medium | `FileChangeDTO.FileType` is `string` instead of an enum. Risk of typos (`"artefact"` vs `"artifact"`). |
| 9 | **Inline model classes** | 🟡 Medium | `FileChangeRecord` and `SyncCheckResponse` are defined inside `sync_service.dart` (not in a models folder), reducing discoverability. |
| 10 | **URL construction uses `Request.Scheme` + `Request.Host`** | 🟡 Medium | Fragile behind reverse proxies. Should use `X-Forwarded-*` headers or configured base URL. |
