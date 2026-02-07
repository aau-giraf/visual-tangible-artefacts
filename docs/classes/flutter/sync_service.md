# SyncService

**File:** `Frontend/vta_app/lib/src/services/sync_service.dart` (1008 lines)

## Purpose

Core bidirectional data synchronization between the local SQLite database and the backend API. Handles artefacts, categories, boards, and saved artefacts. Downloads/uploads assets (images, sounds) as files to local storage.

## Data Types (defined in this file)

| Type | Description |
|------|-------------|
| `FileChangeRecord` | Represents a changed file (artefact or board) with metadata. Factory constructors: `fromJson`, `fromArtefact`, `fromBoard` |
| `SyncCheckResponse` | Contains list of `FileChangeRecord`, check date, and total change count |

## Class: `SyncService`

### Dependencies (all injectable, defaults via GetIt)
`ApiProvider`, `Token`, `UserInfo`, `ArtefactRepository`, `SavedBoardRepository`, `CategoryRepository`, `UserRepository`, `SavedArtefactRepository`, `SyncMetadataRepository`

### Public Methods

| Method | Description |
|--------|-------------|
| `checkForChanges(since)` | GET `Users/Sync/changes?since=`, returns `SyncCheckResponse`, updates local DB |
| `checkLocalChanges(since)` | Queries local SQLite for changes since date (no API call) |
| `syncFromServer(since?)` | **Full bidirectional sync**: downloads all artefacts/categories/boards from API, then uploads local-only items. Default lookback: 365 days |
| `checkForChangesGrouped(since)` | Groups changes by file type (`artefact`/`board`) |
| `getChangeSummary(since)` | GET `Users/Sync/summary?since=`, returns `{total, artefacts, boards}` counts |
| `hasChanges(since)` | Returns `bool` — any changes since date? |
| `getLastSyncDate()` | Reads last sync timestamp from `SyncMetadataRepository` |
| `setLastSyncDate(date)` | Writes sync timestamp |
| `needsSync(threshold)` | Returns `true` if last sync > threshold ago (default: 1 hour) |
| `autoSync(threshold)` | Syncs if `needsSync` returns true |
| `getLocalItemCounts()` | Returns `{artefacts: N, boards: N}` from local DB |

### Sync Algorithm (`syncFromServer`)
1. Fetch all artefacts from API → for each, compare modified dates → download if backend newer, upload if local newer, skip if equal
2. Upload local-only artefacts (not in synced set)
3. Repeat for categories
4. Repeat for boards (including nested saved artefacts)
5. Update sync metadata timestamp

### Asset Management
- Downloads images/sounds to `AppSupport/Synced/{AssetType}/{userId}/` using `_downloadAsset`
- Uploads local files via multipart requests in `_uploadArtefact`/`_uploadCategory`
- `_decideSyncDirection(local, backend)` → `'download'` | `'upload'` | `'skip'`

### Design Notes
- Bidirectional sync with last-write-wins conflict resolution
- No delta tracking — full entity comparison on each sync
- All methods swallow errors (print + return null/false)
- Timestamps stored as Unix seconds in SQLite
