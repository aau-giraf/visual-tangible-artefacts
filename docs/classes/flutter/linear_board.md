# LinearBoard

**File:** `Frontend/vta_app/lib/src/ui/widgets/board/linear_board.dart` (441 lines)

## Purpose

Fixed-slot sequential board widget. Displays artefacts in a horizontal grid of N slots with drag-and-drop reordering, sequential sound playback, and a trash can for deletion.

## Class: `LinearBoard` extends `StatefulWidget`

### Props
- `linearBoardController` — `LinearBoardController` managing the slot array
- `backgroundColor` — board color
- `onArtifactRemoved` — remote sync callback on deletion
- `onArtifactMoved` — remote sync callback `(artifact, fromIndex, toIndex)`

## State: `LinearBoardState` (mixes in `ArtefactSoundPlayer`)

### Layout
- Horizontal `Row` of N `DragTarget<BoardArtefact>` slots separated by vertical dividers
- Grid sized at 85% screen width × 50% screen height
- Each slot: `Expanded` with `LayoutBuilder` for responsive sizing

### Drag & Drop
- Each artefact wrapped in `Draggable<BoardArtefact>` with 0.5 opacity feedback
- Drop on slot: calls `linearBoardController.moveArtifact(fromIndex, toIndex)` + `onArtifactMoved`
- Drop on trash can: removes artefact; Session-Artefacts also deleted server-side via `ArtefactController.deleteArtefact`

### Sequential Sound Playback
- "Afspil Alle Lyde" button at bottom
- Uses `ArtefactSoundPlayer` mixin's `playArtefactSoundAndWait()` for sequential playback
- Toggle behavior: pressing while playing stops via `cleanupArtefactSounds()`

### Trash Can
- `DragTarget<BoardArtefact>` at bottom center, enlarges on drag hover (50→120px)
- Tap: shows confirmation dialog → `removeAllArtifacts()`
- `MouseRegion` for desktop hover styling (red background)

### Design Notes
- No board persistence (unlike TalkingMat) — persistence handled by `ArtifactBoardController` multi-board state
- Listens to controller changes and calls `setState` to rebuild
- Some dialog text in English ("Are you sure..."), some in Danish ("Afspil Alle Lyde")
