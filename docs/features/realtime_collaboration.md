# Feature: Real-time Collaboration

## Summary

Real-time Collaboration allows a **caregiver** and **child** to share a board session over SignalR. The backend **`BoardHub`** (SignalR Hub) manages session lifecycle (request → accept/reject → end), tracks online users with static dictionaries, and relays per-artefact delta events (`ArtifactAdded`, `ArtifactRemoved`, `ArtifactMoved`, `ArtifactResized`, `LayoutChanged`, `FieldCountChanged`). On the Flutter side, **`SignalRService`** (manual singleton) maintains the Hub connection, registers event handlers, and exposes send methods. **`RemoteArtifactBoardController`** (1,209 LOC — the largest file in the codebase) wraps `ArtifactBoardController`, intercepts local board mutations, debounces them, and pushes deltas over SignalR while also applying incoming remote deltas to the local board. Sessions are logged to the database with start/end timestamps for analytics.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend (SyncService) ────────────────────
    namespace Backend {
        class BoardHub {
            -UserConnections Dictionary~string,string~$
            -BoardSessions Dictionary~string,BoardSession~$
            -OnlineUsers HashSet~string~$
            -UserContactsMap Dictionary~string,List~string~~$
            -PendingRequests Dictionary~string,PendingSessionRequest~$
            +RegisterUser(userId, contactIds) Task
            +GetOnlineUsers() List~string~
            +IsUserOnline(userId) bool
            +RequestSession(fromUserId, toUserId) Task
            +AcceptSession(sessionId, fromUserId, toUserId, boardId) Task
            +RejectSession(fromUserId) Task
            +EndSession(sessionId) Task
            +ArtifactAdded(data) Task
            +ArtifactRemoved(data) Task
            +ArtifactMoved(data) Task
            +ArtifactResized(data) Task
            +LayoutChanged(data) Task
            +FieldCountChanged(data) Task
            +UpdateBoard(sessionId, boardData) Task
            +SendOffer(sessionId, targetUserId, sdpOffer) Task
            +SendAnswer(sessionId, targetUserId, sdpAnswer) Task
            +SendIceCandidate(sessionId, targetUserId, candidate) Task
            +OnDisconnectedAsync(exception) Task
        }
        class BoardSession {
            +SessionId string
            +User1Id string
            +User2Id string
            +BoardId string
            +Connections List~string~
        }
        class PendingSessionRequest {
            +FromUserId string
            +ToUserId string
            +RequestTime DateTime
            +TimeoutCts CancellationTokenSource
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class SignalRService {
            «Singleton»
            +connect(userId) Future~void~
            +disconnect() Future~void~
            +loadContacts(token) Future~void~
            +refreshOnlineUsers() Future~void~
            +requestSession(toUserId) Future~void~
            +acceptSession(sessionId, from, to, boardId) Future~void~
            +rejectSession(fromUserId) Future~void~
            +endSession() Future~void~
            +sendArtifactAdded(data) Future~void~
            +sendArtifactRemoved(data) Future~void~
            +sendArtifactMoved(data) Future~void~
            +sendArtifactResized(data) Future~void~
            +sendLayoutChanged(data) Future~void~
            +sendFieldCountChanged(data) Future~void~
            +setOwnerBoardController(controller) void
            +onSessionRequested Callback?
            +onSessionStarted Callback?
            +onSessionEnded Callback?
            +onArtifactAdded Callback?
            +onArtifactRemoved Callback?
            +onArtifactMoved Callback?
            +onArtifactResized Callback?
        }
        class RemoteArtifactBoardController {
            +base ArtifactBoardController
            +isOwner bool
            +sessionId String
            +addArtifact(artefact) void
            +removeArtifact(artefact) void
            +switchBoard() void
            +onArtifactPositionChanged(artifact) void
            +dispose() void
            -_pushArtifactAdded(artifact) Future~void~
            -_pushArtifactRemoved(id) Future~void~
            -_pushArtifactMoved(artifact) Future~void~
            -_pushArtifactResized(artifact) Future~void~
            -_pushLayoutChanged() Future~void~
            -_pushFieldCountChanged(count) Future~void~
            -_pushFullBoard() Future~void~
            -_handleRemoteUpdate(data) void
            -_handleArtifactAdded(data) void
            -_handleArtifactRemoved(data) void
            -_handleArtifactMoved(data) void
        }
        class RemoteBoardScreen {
            «StatefulWidget»
        }
        class RemoteSessionScreen {
            «StatefulWidget»
        }
    }

    %% ── Relationships ────────────────────────────
    SignalRService ..> BoardHub : WebSocket (SignalR)
    RemoteArtifactBoardController --> SignalRService : sends deltas
    RemoteArtifactBoardController --> ArtifactBoardController : wraps (base)
    SignalRService --> ArtifactBoardController : holds _ownerBoardController ref
    RemoteBoardScreen --> RemoteArtifactBoardController : uses
    RemoteSessionScreen --> SignalRService : initiates sessions
    BoardHub --> BoardSession : manages
    BoardHub --> PendingSessionRequest : tracks pending
```

---

## Sequence Diagram — Session Lifecycle (Request → Accept → Collaborate → End)

```mermaid
sequenceDiagram
    actor Caregiver
    actor Child
    participant CG_App as Caregiver Flutter
    participant SR as SignalRService
    participant Hub as BoardHub (Backend)
    participant DB as MySQL
    participant CH_App as Child Flutter

    Note over CG_App,CH_App: Both connected to Hub after login

    Caregiver->>CG_App: Tap "Start session" with child
    CG_App->>SR: requestSession(toUserId)
    SR->>Hub: RequestSession(fromUserId, toUserId)
    Hub->>Hub: Store PendingSessionRequest
    Hub->>Hub: Start 30s timeout task
    Hub->>CH_App: SendAsync("SessionRequested", fromUserId)

    CH_App->>Child: Show incoming session dialog
    Child->>CH_App: Accept
    CH_App->>SR: acceptSession(sessionId, from, to, boardId)
    SR->>Hub: AcceptSession(sessionId, fromUserId, toUserId, boardId)
    Hub->>Hub: Cancel timeout, remove PendingRequest
    Hub->>Hub: Create BoardSession, add both to SignalR group
    Hub->>DB: INSERT Session (startTime)
    Hub->>CG_App: SendAsync("SessionStarted", sessionId, boardId)
    Hub->>CH_App: SendAsync("SessionStarted", sessionId, boardId)

    Note over CG_App,CH_App: Session active — board sync begins

    CG_App->>SR: sendArtifactAdded(data)
    SR->>Hub: ArtifactAdded(JsonElement)
    Hub->>Hub: Validate artefact owner → Broadcast to group
    Hub->>CH_App: SendAsync("ArtifactAdded", data)
    CH_App->>CH_App: RemoteArtifactBoardController._handleArtifactAdded()

    Note over CG_App,CH_App: ... more deltas exchanged ...

    Caregiver->>CG_App: End session
    CG_App->>SR: endSession()
    SR->>Hub: EndSession(sessionId)
    Hub->>DB: UPDATE Session SET duration
    Hub->>Hub: Remove BoardSession, remove group
    Hub->>CG_App: SendAsync("SessionEnded")
    Hub->>CH_App: SendAsync("SessionEnded")
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **RemoteArtifactBoardController is 1,209 LOC** | 🔴 Critical | The largest file in the codebase. Handles delta serialization, debouncing, position/size change tracking, remote event handling, and full-board sync. Decompose into: `DeltaSyncManager` (push/receive deltas), `DebounceManager` (position/size debouncing), `RemoteBoardEventHandler` (incoming event processing). |
| 2 | **Static mutable state in BoardHub** | 🔴 Critical | `UserConnections`, `BoardSessions`, `OnlineUsers`, etc. are `static readonly Dictionary` — **not thread-safe** (should use `ConcurrentDictionary`) and **not scalable** to multiple server instances. For multi-instance deployment, use Redis-backed SignalR backplane with distributed state. |
| 3 | **SignalRService holds reference to ArtifactBoardController** | 🟠 High | `_ownerBoardController` field creates tight coupling between the service layer and controller layer. Use event callbacks or a mediator pattern instead. |
| 4 | **BoardHub is 584 LOC with too many responsibilities** | 🟠 High | Manages sessions, online status, board sync, WebRTC signaling relay, and DB writes. Split into: `SessionHub` (lifecycle), `BoardSyncHub` (delta relay), `WebRTCRelayHub` (signaling). |
| 5 | **No conflict resolution for concurrent board edits** | 🟠 High | If both users move the same artefact simultaneously, last-write-wins. No operational transform or CRDT mechanism. For this use case, consider locking or last-writer-wins with visual feedback. |
| 6 | **Console.WriteLine spam** | 🟡 Medium | ~30 `Console.WriteLine` calls in `BoardHub`. Replace with structured `ILogger<BoardHub>` for proper log levels and filtering. |
| 7 | **30s timeout uses Task.Run with captured Hub context** | 🟡 Medium | The timeout task in `RequestSession` captures `Clients` from the Hub context, which may be disposed after the Hub method returns. Use `IHubContext<BoardHub>` injected via DI for out-of-band sends. |
| 8 | **SignalRService is 532 LOC** | 🟡 Medium | Manages connection lifecycle, user registration, session initiation, delta sending, WebRTC relay, online status, and contact caching. Split into focused services. |
