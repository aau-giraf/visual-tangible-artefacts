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
│   │   ├── models/              # SQLite entity models
│   │   ├── repositories/        # Repository pattern for DB access
│   │   ├── mappers/             # DTO ↔ DB model mappers
│   │   ├── database.dart        # DB initialization
│   │   ├── database_helper.dart # DB operations
│   │   └── database_debug_helper.dart
│   ├── services/                # Backend communication + real-time
│   │   ├── sync_service.dart        # Offline sync orchestration
│   │   ├── sync_timer.dart          # Periodic sync scheduling
│   │   ├── remote_sync_service.dart # Remote data sync
│   │   ├── signalr_service.dart     # SignalR hub connection
│   │   ├── webrtc_service.dart      # WebRTC peer connections
│   │   ├── call_manager.dart        # Audio call management
│   │   ├── video_call_manager.dart  # Video call management
│   │   ├── board_layout_service.dart
│   │   ├── relation_service.dart
│   │   └── notification_service.dart
│   ├── utilities/
│   │   ├── api/                 # HTTP client (ApiProvider)
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
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management (ChangeNotifier) |
| `signalr_netcore` | SignalR client for real-time board sync |
| `flutter_webrtc` | WebRTC for video calling |
| `sqflite` | Local SQLite database |
| `http` | HTTP client for REST API |
| `just_audio` | Audio playback |
| `record` | Audio recording |
| `camera` | Camera access |
| `jwt_decoder` | JWT token parsing |
| `get_it` | Service locator |

## Architecture Pattern

- **MVC-ish**: Controllers (ChangeNotifiers) → Models → Services → API
- **Offline-first**: Local SQLite DB with sync to backend MySQL
- **Provider tree**: Controllers provided at app root, consumed by widgets
- **Singletons**: Token and UserInfo stored globally for auth state

## Configuration

App settings loaded from `assets/cfg/app_settings.json` (gitignored). Contains:
- API base URL
- SyncService URL
- ElevenLabs API key
- TURN server credentials
