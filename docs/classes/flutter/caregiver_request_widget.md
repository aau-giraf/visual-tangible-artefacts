# CaregiverRequestWidget

**File:** `Frontend/vta_app/lib/src/ui/widgets/online_session/caregiver_request_widget.dart` (311 lines)

## Purpose

Sidebar widget for caregivers to initiate remote sessions with children. Displays a list of paired children with call buttons, handles SignalR session request/response flow.

## Class: `CaregiverRequestWidget` extends `StatefulWidget`

### Props
- `caregiverId` — caregiver's user ID
- `children` — list of `ChildInfo` (childId, childName, age?)
- `onSessionStarted(sessionId, childId)` — callback when child accepts

### SignalR Flow
1. On init: connects SignalR with caregiver ID
2. Registers `onSessionRejected` → shows "not ready" message, clears pending state
3. Registers `onSessionStarted` → calls `onSessionStarted` callback
4. **Request session**: `_signalR.requestSession(childId)` → shows "waiting" snackbar

### UI States
- **Connecting**: spinner + "Forbinder..."
- **No children**: icon + "Ingen børn"
- **List**: child cards with name, age, and "Ring op" (call) button
- **Pending**: button disabled, shows spinner + "Venter..."

### Helper Class: `ChildInfo`
Simple data class: `childId`, `childName`, `age?`

### Design Notes
- Fixed 300px width sidebar
- All strings in Danish
- Does not disconnect SignalR on dispose (handled elsewhere)
