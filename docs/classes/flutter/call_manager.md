# CallManager

**File:** `Frontend/vta_app/lib/src/services/call_manager.dart` (217 lines)

## Purpose

Singleton managing incoming/outgoing call UI and navigation. Bridges SignalR session events to Flutter navigation and dialog display.

## Class: `CallManager` (Singleton)

### Setup
- `setupCallbacks({force})` — registers handlers on `SignalRService` for: `onSessionRequested` (shows incoming call dialog), `onSessionStarted` (navigates to video call), `onUserOnlineStatusChanged`, `onMissedCall`
- `clearCallbacks()` — removes all handlers

### Incoming Call Flow (`_showIncomingCallDialog`)
1. Resolves caller display name from `SignalRService` contact cache; refreshes contacts if not found
2. Shows `AlertDialog` with caller name (Danish: "Indgående opkald")
3. **Accept** → generates sessionId from timestamp, calls `signalR.acceptSession()` with `defaultBoardId`
4. **Reject** → calls `signalR.rejectSession()`
5. **Auto-dismiss** after 30 seconds via `Timer`
6. Dismisses immediately on `MissedCall` event (caller hung up)

### Navigation (`_navigateToVideoCall`)
- 500ms delay to allow session state to settle
- Determines `isCaller` by comparing `currentUserId` with `sessionInitiatorId`
- `pushAndRemoveUntil` to `VideoCallScreen`, keeping only first route

### Design Notes
- Uses `MyApp.navigatorKey.currentContext` for global navigation — requires `GlobalKey<NavigatorState>` on `MaterialApp`
- Guard `_isNavigatingToCall` prevents duplicate navigation
- Dialog text is in Danish
