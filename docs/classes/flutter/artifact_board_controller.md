# ArtifactBoardController

**File:** `Frontend/vta_app/lib/src/controllers/artifact_board_controller.dart` (412 lines)

## Purpose

Central controller managing the board UI. Handles multi-board management, dual-mode switching (TalkingMat vs LinearBoard), sequential artefact sound playback, and settings synchronization.

## Class: `ArtifactBoardController` (mixes in `ArtefactSoundPlayer`)

### Constructor
`ArtifactBoardController({notifyView, settingsController})`

Setup:
1. Creates `GlobalKey`s for TalkingMat and LinearBoard widgets
2. Initializes `TalkingmatController` and `LinearBoardController` (default 4 fields)
3. Reads board mode + field count from `SettingsService` (async)
4. Creates default board "Hovedtavle" (Danish: "main board")
5. Applies initial `textUnderImages` setting
6. Listens to `SettingsController` changes

### Multi-Board Management

| Method | Description |
|--------|-------------|
| `createBoard(title)` | Saves active state, creates new `Board`, switches to it |
| `deleteBoard(boardId)` | Prevents deleting last board; switches away first if active |
| `switchBoard(boardId)` | Saves current state, loads target board state |
| `_saveActiveBoardState()` | Snapshots TalkingMat + LinearBoard artefacts, mode, field count into `Board` |
| `_loadBoardState(board)` | Restores mode, field count, and artefacts from `Board` |

### Board Mode Switching

| Method | Description |
|--------|-------------|
| `getCurrentBoardStatus()` | Reads `showDirectionalBoard` from `SettingsService` |
| `switchCurrentBoard()` | Toggles `showDirectional` flag, persists to settings |
| `addArtifactToCurrentBoard(artifact)` | Routes to LinearBoard or TalkingMat based on mode |

### Sequential Sound Playback (`playAllArtefactSounds`)
- Collects artefacts with `soundUrl` from the active board
- Fetches audio from `Users/Artefacts/{id}/play-audio` endpoint (authenticated)
- Plays each sound sequentially via `just_audio` `AudioPlayer`
- Toggle behavior: calling while playing stops playback
- Errors on individual artefacts are caught and skipped

### Settings Sync (`_onSettingsChanged`)
- Syncs `textUnderImages` → updates `nameShown` on all artefacts across both boards
- Syncs `linearArtifactCount` → updates LinearBoard field count
- Triggers full view rebuild

### Callbacks
- `notifyView` — triggers widget rebuild (called after every state change)
- `showMessage` — displays user-facing messages (Danish strings)

### Design Notes
- Not a `ChangeNotifier` — uses manual `notifyView` callback pattern
- Board state is in-memory only (not persisted to backend via `BoardLayoutService`)
- All user-facing strings are hardcoded in Danish
- `_audioPlayer` fetches audio via raw `http.get` rather than through `ApiProvider`
