# Feature: Video Calling

## Summary

Video Calling is layered on top of Real-time Collaboration. Once a session is established via `BoardHub`, a peer-to-peer WebRTC connection is negotiated through SignalR signaling (offer/answer/ICE candidate relay). On the Flutter side, **`WebRTCService`** manages the `RTCPeerConnection`, local/remote media streams, and STUN/TURN configuration (currently hardcoded to `localhost:3478`). **`CallManager`** (singleton) bridges SignalR session events to UI navigation — showing an incoming-call dialog or navigating to `VideoCallScreen`. **`VideoCallManager`** (singleton) persists WebRTC renderers and service references across screen transitions so the video call survives navigation between `VideoCallScreen` and `RemoteBoardScreen`. The backend simply relays SDP offers, answers, and ICE candidates between the two session participants via SignalR group messaging.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class BoardHub {
            +SendOffer(sessionId, targetUserId, sdpOffer) Task
            +SendAnswer(sessionId, targetUserId, sdpAnswer) Task
            +SendIceCandidate(sessionId, targetUserId, candidate) Task
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class WebRTCService {
            +sessionId String
            +hasLocalVideo bool
            +hasLocalAudio bool
            +hasRemoteVideo bool
            +hasRemoteAudio bool
            +onLocalStream Callback?
            +onRemoteStream Callback?
            +onLocalMediaAvailability Callback?
            +onRemoteMediaAvailability Callback?
            +initialize() Future~void~
            +startCall() Future~void~
            +dispose() Future~void~
        }
        class CallManager {
            «Singleton»
            +setupCallbacks(force?) void
            +clearCallbacks() void
            -_showIncomingCallDialog(fromUserId) void
            -_navigateToVideoCall(sessionId, boardId) void
        }
        class VideoCallManager {
            «Singleton»
            +isCallActive bool
            +localRenderer RTCVideoRenderer?
            +remoteRenderer RTCVideoRenderer?
            +webrtcService WebRTCService?
            +currentSessionId String?
            +initializeCall(webrtcService, renderers, sessionId) Future~void~
            +endCall() Future~void~
        }
        class VideoCallScreen {
            «StatefulWidget»
        }
        class CallingScreen {
            «StatefulWidget»
        }
        class IncomingCallScreen {
            «StatefulWidget»
        }
    }

    %% ── External ─────────────────────────────────
    namespace External {
        class COTURN {
            STUN/TURN server
            localhost:3478
        }
    }

    %% ── Relationships ────────────────────────────
    CallManager --> SignalRService : reads session events
    CallManager --> MyApp : navigatorKey (tight coupling)
    CallManager ..> IncomingCallScreen : shows dialog
    CallManager ..> VideoCallScreen : navigates to

    VideoCallScreen --> VideoCallManager : reads renderers
    VideoCallScreen --> WebRTCService : manages call
    VideoCallManager --> WebRTCService : holds reference

    WebRTCService ..> BoardHub : SDP/ICE via SignalR
    WebRTCService ..> COTURN : STUN/TURN for NAT traversal
    SignalRService ..> BoardHub : SendOffer/SendAnswer/SendIceCandidate
```

---

## Sequence Diagram — Establish Video Call

```mermaid
sequenceDiagram
    actor Caregiver
    participant CG as Caregiver Flutter
    participant CM as CallManager
    participant SR as SignalRService
    participant Hub as BoardHub
    participant CH as Child Flutter
    participant WebRTC_CG as WebRTCService (Caller)
    participant WebRTC_CH as WebRTCService (Callee)
    participant TURN as COTURN Server

    Note over CG,CH: Session already established (see Real-time Collaboration)

    CG->>CM: onSessionStarted(sessionId, boardId)
    CM->>CG: Navigate to VideoCallScreen
    CG->>WebRTC_CG: initialize()
    WebRTC_CG->>WebRTC_CG: getUserMedia() → localStream
    WebRTC_CG->>WebRTC_CG: createPeerConnection(STUN/TURN config)
    WebRTC_CG->>WebRTC_CG: addLocalStream to peerConnection

    CG->>WebRTC_CG: startCall()
    WebRTC_CG->>WebRTC_CG: createOffer() → SDP offer
    WebRTC_CG->>SR: sendOffer(sessionId, targetUserId, sdpOffer)
    SR->>Hub: SendOffer(sessionId, targetUserId, sdpOffer)
    Hub->>CH: ReceiveOffer(sessionId, sdpOffer)

    CH->>WebRTC_CH: handleOffer(sdpOffer)
    WebRTC_CH->>WebRTC_CH: setRemoteDescription(offer)
    WebRTC_CH->>WebRTC_CH: createAnswer() → SDP answer
    CH->>SR: sendAnswer(sessionId, targetUserId, sdpAnswer)
    SR->>Hub: SendAnswer(sessionId, targetUserId, sdpAnswer)
    Hub->>CG: ReceiveAnswer(sessionId, sdpAnswer)
    CG->>WebRTC_CG: setRemoteDescription(answer)

    par ICE Candidate Exchange
        WebRTC_CG->>SR: sendIceCandidate(candidate)
        SR->>Hub: SendIceCandidate(sessionId, targetUserId, candidate)
        Hub->>CH: ReceiveIceCandidate(candidate)
        CH->>WebRTC_CH: addIceCandidate(candidate)
    and
        WebRTC_CH->>SR: sendIceCandidate(candidate)
        SR->>Hub: SendIceCandidate(sessionId, targetUserId, candidate)
        Hub->>CG: ReceiveIceCandidate(candidate)
        CG->>WebRTC_CG: addIceCandidate(candidate)
    end

    WebRTC_CG->>TURN: P2P media flow (via TURN relay if needed)
    WebRTC_CH->>TURN: P2P media flow
    Note over CG,CH: Video call active — both see each other's video/audio
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **Hardcoded TURN credentials and localhost URLs** | 🔴 Critical | `WebRTCService` has `username: 'testuser'`, `credential: 'testpass'`, `urls: 'stun:localhost:3478'`. This will **not work** in production or across networks. Must be configurable via environment/config (ideally use a TURN credential provisioning API with short-lived tokens). |
| 2 | **CallManager tightly coupled to app root** | 🟠 High | `CallManager` imports `MyApp` and uses `MyApp.navigatorKey.currentContext` for navigation. If the app is restructured or the navigator key changes, calls break silently. Use a navigation service abstraction injected via DI. |
| 3 | **WebRTCService takes raw HubConnection** | 🟠 High | Creates coupling between WebRTC and SignalR implementations. If the signaling transport changes (e.g., to WebSocket or Firebase), `WebRTCService` needs rewriting. Abstract signaling behind an interface (`ISignalingService`). |
| 4 | **No call state machine** | 🟡 Medium | Call state transitions (idle → ringing → connecting → connected → ended) are implicit across `CallManager`, `SignalRService`, and `VideoCallManager`. A formal state machine would prevent invalid transitions and race conditions. |
| 5 | **Graceful degradation is ad-hoc** | 🟡 Medium | `WebRTCService._requestUserMedia()` has a cascade fallback (video+audio → video-only → audio-only → no media) but the UI doesn't clearly communicate which mode the call is in. |
| 6 | **VideoCallManager is thin (52 LOC)** | 🟢 Low | Currently just a state holder. Consider whether `WebRTCService` itself could persist across screen transitions, eliminating the need for a separate manager. |
