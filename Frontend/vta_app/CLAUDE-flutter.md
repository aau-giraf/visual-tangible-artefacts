# Flutter App — Claude Code Guide

## Directory Structure

```
Frontend/vta_app/lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp + routing
├── theme/                       # App theme definitions
├── src/
│   ├── controllers/             # ChangeNotifier controllers (business logic)
│   ├── models/                  # Client-side domain models
│   ├── modelsDTOs/              # API data transfer objects
│   ├── database/                # Local SQLite database layer
│   │   ├── models/              # SQLite entity models (*DB classes with toMap/fromMap)
│   │   ├── repositories/        # Repository pattern for DB access
│   │   ├── mappers/             # DTO ↔ DB model mappers
│   │   ├── database.dart        # Barrel export for all DB types
│   │   ├── database_helper.dart # Singleton DB instance + schema (version 2)
│   │   └── database_debug_helper.dart
│   ├── services/                # Backend communication + sync + real-time
│   │   ├── sync_service.dart        # Thin orchestrator: download → upload per entity type
│   │   ├── sync_downloader.dart     # Server → local sync (RetryHelper + SQLite transactions)
│   │   ├── sync_uploader.dart       # Local → server sync (RetryHelper + error tracking)
│   │   ├── sync_change_detector.dart# Query API/local DB for change records
│   │   ├── sync_models.dart         # SyncResult, EntitySyncStats, SyncError, FileChangeRecord
│   │   ├── sync_timer.dart          # Periodic sync with exponential backoff on failure
│   │   ├── remote_sync_service.dart # Remote data sync
│   │   ├── remote_board_sync_sender.dart   # Outbound SignalR board deltas
│   │   ├── remote_board_sync_receiver.dart # Inbound SignalR board event handlers
│   │   ├── signalr_service.dart     # SignalR facade (session/board/WebRTC invoke wrappers)
│   │   ├── signalr_connection_manager.dart # Hub connection lifecycle
│   │   ├── signalr_event_router.dart      # All .on() handler registrations
│   │   ├── online_status_tracker.dart     # Track/refresh/query online users
│   │   ├── board_layout_service.dart
│   │   ├── relation_service.dart
│   │   ├── call_manager.dart        # Audio call management
│   │   ├── video_call_manager.dart  # Video call management
│   │   ├── webrtc_service.dart      # WebRTC peer connections
│   │   └── notification_service.dart
│   ├── utilities/
│   │   ├── api/                 # HTTP client (ApiProvider — returns Response?, null on failure)
│   │   ├── retry_helper.dart    # Exponential backoff + jitter for HTTP/async ops
│   │   ├── app_logger.dart      # AppLogger.init() — configures package:logging
│   │   ├── audio/               # Audio recording/playback
│   │   ├── config/              # App configuration
│   │   ├── data/                # DataRepository, ImageData
│   │   ├── extensions/          # Dart extension methods
│   │   ├── json/                # JSON utilities
│   │   └── services/            # Camera service
│   ├── singletons/              # Global state (Token, UserInfo)
│   ├── settings/                # Settings management
│   ├── notifiers/               # ValueNotifier wrappers
│   ├── shared/                  # Shared constants/types
│   ├── functions/               # Utility functions
│   ├── localization/            # i18n (ARB-based)
│   ├── ui/
│   │   ├── screens/             # Full-page screens (12 screens)
│   │   └── widgets/
│   │       ├── board/           # Board-related widgets
│   │       ├── categories/      # Category picker widgets
│   │       ├── online_session/  # Collaboration UI
│   │       ├── video/           # Video call widgets
│   │       └── utilities/       # Shared UI utilities
│   └── views/                   # Top-level view compositions
```

## Build & Run

```bash
cd Frontend/vta_app
flutter pub get                  # Install dependencies
flutter run                      # Run on connected device/emulator
flutter run -d chrome             # Run on web (for quick testing)
flutter test                     # Unit tests
flutter test integration_test/    # Integration tests (needs device)
flutter analyze                  # Static analysis
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management (ChangeNotifier) |
| `signalr_netcore` | SignalR client for real-time board sync |
| `flutter_webrtc` | WebRTC for video calling |
| `sqflite` | Local SQLite database |
| `http` | HTTP client for REST API |
| `logging` | Structured logging (replaces print/debugPrint) |
| `just_audio` | Audio playback |
| `record` | Audio recording |
| `camera` | Camera access |
| `jwt_decoder` | JWT token parsing |
| `get_it` | Service locator |

## Architecture Pattern

- **MVC-ish**: Controllers (ChangeNotifiers) → Models → Services → API
- **Offline-first**: Local SQLite DB with bidirectional sync to backend MySQL
- **Provider tree**: Controllers provided at app root, consumed by widgets
- **Singletons**: Token and UserInfo stored globally for auth state
- **Service locator**: `GetIt` for DI — services accept optional constructor params, fall back to `GetIt.instance.get<T>()`

## Logging Convention

All files use `package:logging` with a file-scoped named logger:

```dart
import 'package:logging/logging.dart';
final _log = Logger('ClassName');

// Usage:
_log.info('message');       // normal operation
_log.warning('message');    // unexpected but recoverable
_log.severe('message');     // errors
_log.fine('message');       // debug / dispose / cleanup
```

`AppLogger.init()` is called once in `main.dart` to configure the root logger (hierarchical, outputs to console in debug builds).

**Never use `print()` or `debugPrint()`** — the codebase was fully migrated to `package:logging`.

## Sync Architecture

The sync subsystem is split into focused classes:

```
SyncTimer (periodic trigger, exponential backoff on failure)
  └── SyncService (thin orchestrator)
        ├── SyncDownloader.downloadArtefacts/Categories/Boards()
        │     → RetryHelper.runHttp() for API calls
        │     → RetryHelper.run() for asset downloads
        │     → SQLite db.transaction() for batch writes
        │     → Returns DownloadResult { syncedIds, EntitySyncStats, errors }
        ├── SyncUploader.uploadLocalArtefacts/Categories/Boards()
        │     → RetryHelper.run() for multipart uploads
        │     → RetryHelper.runHttp() for JSON posts
        │     → Returns UploadResult { EntitySyncStats, errors }
        └── SyncChangeDetector (remote/local change queries)
```

**Key types:**
- `SyncResult` — aggregated result of a full sync pass (replaces old `bool` return). Has `success`, `partial`, `totalDownloaded`, `totalUploaded`, `totalFailed` getters.
- `EntitySyncStats` — per-entity-type succeeded/failed/skipped counts.
- `SyncError` — detailed error record with entity type, ID, message, timestamp.
- `DownloadResult` / `UploadResult` — per-pass results with IDs + stats + errors.

**RetryHelper** (`lib/src/utilities/retry_helper.dart`):
- `RetryHelper.run<T>()` — generic async retry with exponential backoff + jitter
- `RetryHelper.runHttp()` — HTTP-aware variant that skips retry for 401/403/404
- Default: 3 attempts, 500ms initial delay, doubles per attempt
- Returns `RetryResult<T>` with value, success flag, and attempt count

**SyncTimer backoff:**
- Default interval: 30 seconds
- On consecutive failures: 30s → 60s → 120s → … → max 5 minutes
- Resets to default on first successful sync

## SignalR Architecture

The SignalR client is split into focused classes:

```
SignalRService (public facade — session/board/WebRTC invoke wrappers)
  ├── SignalRConnectionManager (connect/disconnect/reconnect lifecycle)
  ├── SignalREventRouter (all .on() callback registrations)
  └── OnlineStatusTracker (online user list management)
```

**Critical**: Hub method names and Flutter callback names must match exactly (string-based). The Flutter client uses `signalr_netcore`, NOT the official Microsoft package.

## Database

- **Engine**: `sqflite` with singleton `DatabaseHelper.instance`
- **Schema version**: 2 (7 tables: user, category, artefact, saved_board, saved_artefact, session_meta, sync_metadata)
- **Repository pattern**: One repository per table (e.g. `ArtefactRepository`, `SavedBoardRepository`)
- **Transactions**: Sync downloads use `db.transaction((txn) => ...)` for batch writes
- **Models**: `*DB` classes with `toMap()` / `fromMap()` for SQLite serialization

## Configuration

App settings loaded from `assets/cfg/app_settings.json` (gitignored). Contains:
- API base URL
- SyncService URL
- ElevenLabs API key
- TURN server credentials

## API Client

`ApiProvider` wraps `package:http`:
- Methods: `fetchAsJson`, `postAsJson`, `patchAsJson`, `putAsJson`, `delete`, `sendAsMultiPart`
- **Returns `Response?`** — returns `null` on exception (no retry at this level)
- Callers must null-check AND verify `response.statusCode`
- Sync callers wrap ApiProvider calls in `RetryHelper` for transient failure resilience
