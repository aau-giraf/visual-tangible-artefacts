# CallingScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/calling_screen.dart`

## Overview
The `CallingScreen` is the outgoing call interface. It is shown to the caller (caregiver) while they wait for the recipient (child) to accept the session request.

## Responsibilities
- **Call Initiation:** Sends the initial session request via SignalR immediately upon mounting (or via post-frame callback).
- **Status Feedback:** Displays "Calling..." or similar status to the user.
- **Timeout/Rejection Handling:** Handles events where the call is rejected (`onSessionRejected`) or times out.
- **Pulse Animation:** Visual feedback (pulsing icon) to indicate an active waiting state.
- **Navigation:** automatically navigates to the active session view (`/video-call` or `/remote-board`) once the `onSessionStarted` event is received.

## Key Methods
- `_initiateCall()`: Triggers the `requestSession` command on the backend.
- `_setupSignalRListeners()`: Temporarily overrides SignalR callbacks to handle acceptance or rejection specific to this screen context.

## Dependencies
- `SignalRService`: Used to send the call request and listen for the response.
