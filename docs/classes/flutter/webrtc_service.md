# WebRTCService

**File:** `Frontend/vta_app/lib/src/services/webrtc_service.dart` (432 lines)

## Purpose

Manages a WebRTC peer connection for video/audio calling between two users. Handles media capture, offer/answer negotiation, ICE candidates, and media track management. Uses SignalR as the signaling channel.

## Class: `WebRTCService`

### Constructor
`WebRTCService({hubConnection, sessionId, myUserId, remoteUserId})`

### Initialization (`initialize()`)
1. Requests user media with graceful fallback: video+audio → video only → audio only → no media
2. Sets up SignalR callbacks for WebRTC signaling
3. Creates `RTCPeerConnection` with STUN/TURN config
4. Registers handlers: `onConnectionState`, `onIceCandidate`, `onTrack`
5. Adds local tracks to peer connection
6. Flushes queued SignalR messages

### STUN/TURN Configuration
- STUN: `stun:localhost:3478`
- TURN: `turn:localhost:3478` (TCP and UDP)
- Credentials: `testuser`/`testpass` (hardcoded for COTURN)
- SDP semantics: `unified-plan`

### Call Flow
**Caller:** `startCall()` → creates SDP offer → sends via `SendOffer` SignalR method
**Callee:** Receives offer → sets remote description → creates answer → sends via `SendAnswer`
**Both:** Exchange ICE candidates via `SendIceCandidate`/`ReceiveIceCandidate`

### Media Management
| Method | Description |
|--------|-------------|
| `toggleMute()` | Enables/disables local audio track |
| `toggleCamera()` | Enables/disables local video track |

### Callbacks
`onLocalStream`, `onRemoteStream`, `onError`, `onLocalMediaAvailability`, `onRemoteMediaAvailability`, `onConnectionEstablished`

### SDP Analysis
`_sdpHasVideo(sdp)`, `_sdpHasAudio(sdp)` — parses SDP to detect which media types the remote peer offers (checks for `m=video`/`m=audio` lines not set to port 0).

### Design Notes
- Adds `RecvOnly` transceivers for media types not available locally, ensuring the peer can still send
- ICE candidates that arrive before peer connection is ready are queued in `_pendingIceCandidates`
- TURN credentials are hardcoded — should be environment-configured
- `dispose()` clears SignalR callbacks, stops all tracks, closes peer connection
