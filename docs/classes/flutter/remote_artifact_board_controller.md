# RemoteArtifactBoardController

**File:** `Frontend/vta_app/lib/src/controllers/remote_artifact_board_controller.dart` (1208 lines)

## Purpose

Wraps `ArtifactBoardController` to add real-time board synchronization via SignalR during remote collaboration sessions. Owner-driven model: only the owner can modify the board; non-owners receive read-only mirror updates.

## Class: `RemoteArtifactBoardController`

### Constructor
`RemoteArtifactBoardController({sessionId, notifyView, settingsController, isOwner, existingController?})`

Setup:
1. Registers 7 SignalR delta-update handlers (board updated, artifact added/removed/moved/resized, layout changed, field count changed)
2. **Owner:** sets up position/size/remove callbacks on TalkingMat and LinearBoard widgets, listens for artifact additions and field count changes
3. **Non-owner:** clears board and waits for state from owner

### Architecture: Owner/Non-Owner Split

| Concern | Owner | Non-owner |
|---------|-------|-----------|
| Add/remove/move artifacts | Allowed → pushes delta via SignalR | Blocked (early return) |
| Receives SignalR updates | Ignores (returns early) | Applies to local board |
| Board widgets | Rebuilt with sync callbacks | Read-only TalkingMat |
| Auto-save | Triggers via TalkingMat state | Disabled |

### Delta Update Protocol (SignalR methods)

**Push (owner → SignalR):**
| Method | Payload |
|--------|---------|
| `_pushArtifactAdded` | `{sessionId, artifact: {savedArtefactId, id, name, imageUrl, soundUrl, size, position?}}` |
| `_pushArtifactRemoved` | `{sessionId, savedArtefactId}` |
| `_pushArtifactMoved` | `{sessionId, savedArtefactId, position}` (TalkingMat) or `{..., fromIndex, toIndex}` (LinearBoard) |
| `_pushArtifactResized` | `{sessionId, savedArtefactId, size}` |
| `_pushLayoutChanged` | `{sessionId, layout}` |
| `_pushFieldCountChanged` | `{sessionId, count}` |
| `_pushFullBoard` | Full snapshot with all items (used on initial load + after layout change) |

**Receive (non-owner):**
Each handler validates `sessionId`, filters owner out, then applies the delta to the local board.

### Debouncing
- Size updates: 100ms per-artifact timer
- Layout changes: 300ms + 100ms delayed full board push
- Position updates: sent immediately (no debounce)

### Helper Functions (top-level)
- `_fixLocalhostUrl(url)` — replaces `localhost:5192` with platform-appropriate API URL
- `_generateSavedArtefactId()` — generates UUID v4 for artifact instance identification

### Design Notes
- `savedArtefactId` distinguishes artifact instances (same artefact placed twice gets different IDs)
- Owner generates IDs for all artifacts; non-owner uses received IDs
- Full board snapshot used as fallback sync mechanism (after layout changes)
- Commented-out `_loadBoardFromBackend` — future feature for loading saved boards into sessions
- Dispose carefully unregisters all SignalR handlers and timers; only disposes base controller if non-owner
