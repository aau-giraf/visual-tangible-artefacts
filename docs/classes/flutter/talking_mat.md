# TalkingMat

**File:** `Frontend/vta_app/lib/src/ui/widgets/board/talking_mat.dart` (1101 lines)

## Purpose

Free-form board widget where artefacts can be placed and dragged to any position. Handles drag-and-drop, z-ordering, trash can deletion, auto-save to backend board layouts, and board restore on startup.

## Class: `TalkingMat` extends `StatefulWidget`

### Props
- `controller` — `TalkingmatController` (ValueNotifier of artefact list)
- `width` / `height` / `backgroundColor` — layout
- `onArtifactPositionChanged` — remote sync callback on drag end
- `onArtifactRemoved` — remote sync callback on deletion
- `onBoardLoaded` — fires after initial board restore completes
- `readOnly` — disables drag/interaction (used by non-owner in remote sessions)

## State: `TalkingMatState`

### Board Persistence
- On init: loads saved boards from `BoardLayoutService.getBoards()`, finds "Current Board", restores artefact positions/sizes via `_restoreArtefactsFromBoard()`
- **Auto-save:** debounced 1s after position/size changes + periodic 30s timer + immediate on app pause/detach
- **Save logic (`_autoSaveBoardLayout`):**
  - Existing artefacts (have `savedArtefactId` in `_backendSavedArtefactIds`): PATCH via `updateArtefactLayout` (only if changed)
  - New artefacts: full PUT via `updateBoard` then maps returned `savedArtefactId`s back to local artifacts by nearest-position matching
- `_inhibitAutoSave` flag prevents saves during deletion operations
- `_isRemoteSession` flag disables all auto-save during remote collaboration

### Artefact Restore (`_restoreArtefactsFromBoard`)
- Matches saved layouts to local artefacts by `artefactId` + nearest position (Euclidean distance)
- Unmatched saved artefacts: fetched from API via `ArtifactRepository.fetchArtefact()` and added to board
- Sets `savedArtefactId`, position, size, and `nameVisible` on matched artefacts
- Fires `onBoardLoaded` callback when complete

### Drag & Drop
- Each artefact wrapped in `Draggable<BoardArtefact>` (unless `readOnly` or resizing)
- On drag start: z-order bumped via `Expando<int>` tick counter
- On drag end: position clamped to board bounds, adjusted for name label offset
- `LongPressOptionWheel` wraps each artefact for context menu

### Trash Can
- `DragTarget<BoardArtefact>` at bottom center, enlarges on hover
- On accept: deletes `savedArtefact` from backend → removes from controller → notifies remote session
- Special handling for "Session-Artefact" category: also deletes the artefact itself via `ArtefactController`
- Tap (non-drag): shows confirmation dialog → clears all artefacts from board and backend

### Public Methods
| Method | Description |
|--------|-------------|
| `setRemoteSession(bool)` | Enables/disables auto-save for remote sessions |
| `triggerAutoSave()` | Immediate save (called by external controllers) |
| `forceAutoSave()` | Awaitable immediate save |
| `saveBoardAs(name)` | Creates new named board, returns boardId |
| `loadBoard(boardId)` | Loads a specific saved board |
| `getSavedBoards()` | Returns list of saved boards |

### Design Notes
- 1101 lines — complex widget combining UI, persistence, and remote sync concerns
- Z-ordering uses `Expando` (weak map) to avoid modifying artefact objects
- `_assignReturnedSavedIdsToLocal` uses nearest-position matching (not exact ID match) to handle backend ID assignment for duplicate artefacts
- Size measurement via `GlobalKey` + `addPostFrameCallback`, suppressed during drag to prevent cascade resizes
- `WidgetsBindingObserver` triggers save on app lifecycle changes
