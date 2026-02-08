# Simple Services Summary

**Path:** `Frontend/vta_app/lib/src/services/`

## Files

| File | Lines | Class | Description |
|------|-------|-------|-------------|
| `remote_sync_service.dart` | 28 | `RemoteSyncService` (singleton) | Sends/receives board updates via `SignalRService.updateBoard()`. Thin wrapper. |
| `video_call_manager.dart` | 51 | `VideoCallManager` (singleton) | Holds video call state (RTCVideoRenderers, WebRTCService, sessionId) across screen transitions |
| `notification_service.dart` | 121 | `NotificationService` (singleton) | Initializes `flutter_local_notifications` for Android/iOS, shows missed-call notifications |
| `relation_service.dart` | 38 | `RelationService` | Fetches caregiver-child pairings from `Contacts/pairings` endpoint via `ApiProvider` |
| `sync_timer.dart` | 108 | `SyncTimer` (singleton) | Periodic timer (configurable interval) that calls `SyncService.autoSync()`. Start/stop/reset lifecycle. |
