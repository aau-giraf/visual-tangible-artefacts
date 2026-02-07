# VideoCallScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/video_call_screen.dart`

## Overview
The `VideoCallScreen` is a StatefulWidget responsible for managing the active video call interface. It handles WebRTC connection setup, renders local and remote video streams, and manages call state transitions (connecting, connected, error, etc.).

## Responsibilities
- **WebRTC Management:** Initializes and manages `WebRTCService` for peer-to-peer connection using the provided SignalR hub connection.
- **Video Rendering:** Manages `RTCVideoRenderer` instances for both local and remote video feeds, including handling camera and microphone availability.
- **Connection State:** Tracks and displays the current connection status (`initializing`, `calling`, `connecting`, `connected`, `error`).
- **Session Management:** Listens for session end events (remote hang-up) and navigates the user appropriately (back to contacts or board).
- **State Restoration:** Can restore call state if returning from another screen (e.g., the artifact board) while a call is active.

## Key Properties
- `hubConnection`: The active SignalR hub connection used for signaling.
- `sessionId`: Unique identifier for the current session.
- `myUserId`: The local user's ID.
- `remoteUserId`: The remote user's ID.
- `isCaller`: Boolean indicating if the local user initiated the call.
- `returnFromBoard`: Boolean indicating if this screen is being pushed back from the board view (to restore state).

## Key Methods
- `_initializeCall()`: Sets up renderers, initializes `WebRTCService`, defines callbacks for streams and media availability, and handles connection establishment.
- `_restoreCallState()`: Reattaches to the existing `VideoCallManager` service and renderers if returning to the screen during an active call.
- `_handleConnectionEstablished()`: Logic to execute once the WebRTC connection is stable.

## Dependencies
- `WebRTCService`: Handles the low-level WebRTC peer connection logic.
- `VideoCallManager`: Singleton that persists call state across navigation.
- `SignalRService`: Provides real-time signaling events (e.g., `onSessionEnded`).
