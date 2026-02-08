# IncomingCallScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/incomming_call_screen.dart`

## Overview
The `IncomingCallScreen` is a dedicated view shown to a user (typically a child) when they receive a session request (call) from a caregiver. It provides a simple, high-visibility UI to accept the call.

## Responsibilities
- **Notification:** Visually alerts the user of an incoming call, displaying the caller's name.
- **Response Handling:** Provides a mechanism (usually a large button) to accept the session.
- **Session Acceptance:** Calls `SignalRService().acceptSession()` to establish the handshake.
- **Navigation:** Redirects the user to the active session screen (`/remote-board`) upon successful connection.
- **Animation:** Uses a pulse animation for the call icon to draw attention.

## Key Methods
- `_acceptCall()`: Async method that triggers the session acceptance via SignalR. It handles the specific logic of joining the session with a default board ID.
- `_listenForSessionStart()`: Listens to the `onSessionStarted` event from SignalR to know when the handshake is complete and navigation should occur.

## Dependencies
- `SignalRService`: Used to send the `acceptSession` command and listen for the confirmation event.

## Navigation Arguments
- `caregiverId`: ID of the user initiating the call.
- `caregiverName`: Display name of the caller.
- `childId`: ID of the recipient (the current user).
