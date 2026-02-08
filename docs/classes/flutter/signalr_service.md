# SignalRService

**File:** `Frontend/vta_app/lib/src/services/signalr_service.dart` (531 lines)

## Purpose

Singleton managing the SignalR hub connection to the SyncService backend. Handles real-time board collaboration sessions, WebRTC signaling, user online status, and delta board updates.

## Class: `SignalRService` (Singleton)

### Connection
- `connect(userId)` — builds `HubConnection` to `{SyncServiceUrl}/boardHub` with JWT auth, auto-reconnect. After connecting: loads contacts from API, registers user with backend, refreshes online users.
- `disconnect()` — stops connection, clears all state and callbacks

### State
| Field | Type | Description |
|-------|------|-------------|
| `_currentUserId` | `String?` | Logged-in user |
| `_currentSessionId` | `String?` | Active collaboration session |
| `_sessionInitiatorId` | `String?` | Who started the session |
| `_remoteUserId` | `String?` | Other participant |
| `_onlineUsers` | `Set<String>` | Tracked online users |
| `_contactCache` | `Map<String, String>` | userId → display name |
| `_ownerBoardController` | `ArtifactBoardController?` | Owner's board for remote sessions |

### Event Callbacks (set by UI/controllers)

**Session lifecycle:**
`onSessionRequested`, `onSessionRejected`, `onSessionStarted`, `onBoardUpdated`, `onSessionEnded`

**Online status:** `onUserOnlineStatusChanged`

**Delta updates:** `onArtifactAdded`, `onArtifactRemoved`, `onArtifactMoved`, `onArtifactResized`, `onLayoutChanged`, `onFieldCountChanged`

**WebRTC signaling:** `onReceiveOffer`, `onReceiveAnswer`, `onReceiveIceCandidate` — with message queuing for messages arriving before WebRTC service is ready

**Missed calls:** `onMissedCall` — triggers local notification via `NotificationService`

### Hub Methods (invoked on server)

| Method | Args | Description |
|--------|------|-------------|
| `RegisterUser` | userId, contactIds | Register with server |
| `RequestSession` | fromUserId, toUserId | Initiate collaboration |
| `AcceptSession` | sessionId, fromUserId, toUserId, boardId | Accept request |
| `RejectSession` | fromUserId | Decline request |
| `UpdateBoard` | sessionId, boardData | Full board sync |
| `EndSession` | sessionId | End collaboration |
| `ArtifactAdded/Removed/Moved/Resized` | data | Delta updates |
| `LayoutChanged`, `FieldCountChanged` | data | Board config changes |

### Design Notes
- Uses `signalr_netcore` package
- `defaultBoardId = "default-shared-board"` — workaround until multi-board support
- WebRTC messages queued in `_pendingOffers/Answers/IceCandidates` until handlers are registered, flushed via `flushWebRTCQueue()`
- Contact names resolved from cache; missed calls fall back to backend-provided name
