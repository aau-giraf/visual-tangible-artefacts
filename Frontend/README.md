# Frontend setup
To be made at a later stage


# Frontend folder structure
This section show the folder structure with some infomation on the files
(But will not include the admin-dashboard since it is outdated)

```
Frontend/vta_app/lib/
├── app.dart                     # MaterialApp + routing
├── main.dart                    # App entry point
├── src/
│   ├── controllers/             # ChangeNotifier controllers (business logic)
│   ├── database/                # Local SQLite database layer
│   │   ├── database.dart        # Barrel export for all DB types
│   │   ├── database_debug_helper.dart
│   │   ├── database_helper.dart # Singleton DB instance + schema (version 2)
│   │   ├── mappers/             # DTO ↔ DB model mappers
│   │   ├── models/              # SQLite entity models (*DB classes with toMap/fromMap)
│   │   └── repositories/        # Repository pattern for DB access
│   ├── functions/               # Utility functions
│   ├── localization/            # i18n (ARB-based)
│   ├── models/                  # Client-side domain models
│   ├── modelsDTOs/              # API data transfer objects
│   ├── notifiers/               # ValueNotifier wrappers
│   ├── services/                # Backend communication + sync + real-time
│   │   ├── board_layout_service.dart
│   │   ├── call_manager.dart        # Audio call management
│   │   ├── notification_service.dart
│   │   ├── online_status_tracker.dart     # Track/refresh/query online users
│   │   ├── relation_service.dart
│   │   ├── remote_board_sync_receiver.dart # Inbound SignalR board event handlers
│   │   ├── remote_board_sync_sender.dart   # Outbound SignalR board deltas
│   │   ├── remote_sync_service.dart # Remote data sync
│   │   ├── signalr_connection_manager.dart # Hub connection lifecycle
│   │   ├── signalr_event_router.dart      # All .on() handler registrations
│   │   ├── signalr_service.dart     # SignalR facade (session/board/WebRTC invoke wrappers)
│   │   ├── sync_change_detector.dart# Query API/local DB for change records
│   │   ├── sync_downloader.dart     # Server → local sync (RetryHelper + SQLite transactions)
│   │   ├── sync_models.dart         # SyncResult, EntitySyncStats, SyncError, FileChangeRecord
│   │   ├── sync_service.dart        # Thin orchestrator: download → upload per entity type
│   │   ├── sync_timer.dart          # Periodic sync with exponential backoff on failure
│   │   ├── sync_uploader.dart       # Local → server sync (RetryHelper + error tracking)
│   │   ├── video_call_manager.dart  # Video call management
│   │   └── webrtc_service.dart      # WebRTC peer connections
│   ├── settings/                # Settings management
│   ├── shared/                  # Shared constants/types
│   ├── singletons/              # Global state (Token, UserInfo)
│   ├── ui/
│   │   ├── screens/             # Full-page screens (12 screens)
│   │   └── widgets/
│   │       ├── board/           # Board-related widgets
│   │       ├── categories/      # Category picker widgets
│   │       ├── online_session/  # Collaboration UI
│   │       ├── utilities/       # Shared UI utilities
│   │       └── video/           # Video call widgets
│   ├── utilities/
│   │   ├── api/                 # HTTP client (ApiProvider — returns Response?, null on failure)
│   │   ├── app_logger.dart      # AppLogger.init() — configures package:logging
│   │   ├── audio/               # Audio recording/playback
│   │   ├── config/              # App configuration
│   │   ├── data/                # DataRepository, ImageData
│   │   ├── extensions/          # Dart extension methods
│   │   ├── json/                # JSON utilities
│   │   ├── retry_helper.dart    # Exponential backoff + jitter for HTTP/async ops
│   │   └── services/            # Camera service
│   └── views/                   # Top-level view compositions
└── theme/                       # App theme definitions
```