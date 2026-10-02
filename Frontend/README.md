# Frontend setup
To be made at a later stage


# Frontend folder structure
This section show the folder structure with some infomation on the files
(But will not include the admin-dashboard since it is outdated)

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