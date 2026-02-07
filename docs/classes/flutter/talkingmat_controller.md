# TalkingmatController

**File:** `Frontend/vta_app/lib/src/controllers/talkingmat_controller.dart` (254 lines)

## Purpose

ValueNotifier managing the list of `BoardArtefact`s on the TalkingMat board. Wraps the artefact list in a mutation-watching proxy for debugging.

## Class: `TalkingmatController` extends `ValueNotifier<List<BoardArtefact>>`

### Constructor
`TalkingmatController({initialArtifacts?, onArtefactAdded})` — assigns a unique instance ID (static counter), wraps list in `_WatchedList`.

### Methods

| Method | Description |
|--------|-------------|
| `addArtifact(artefact)` | Appends to list, fires `onArtefactAdded` callback, notifies |
| `removeArtifact(artefact)` | Removes by `savedArtefactId` if available, else first match by `artefactId` |
| `removeAllArtifacts({context})` | Shows confirmation dialog before clearing |
| `setNamesVisibleForAll(visible)` | Toggles `nameVisible` on all artefacts |
| `refresh()` | Triggers `notifyListeners()` without mutation |

### `_WatchedList` (private helper)

A `ListBase<BoardArtefact>` wrapper that intercepts `clear()`, `remove()`, `removeAt()`, `removeWhere()`, `length=`, and `[]=` — logs mutations and auto-calls `notifyListeners()`. Prints stack traces when the list is unexpectedly cleared (debugging aid for a past bug).

### Value Setter Override
The `value` setter logs length changes and wraps incoming lists in `_WatchedList` if not already wrapped. Prints stack traces on suspicious clears (e.g., setting to empty from non-empty).

### Design Notes
- Heavy debug logging throughout — added to track down an artefact-disappearing bug
- `add()` and `addAll()` on `_WatchedList` do NOT call `notifyListeners()` (only `addArtifact()` does)
- Confirmation dialog text is in Danish
- Instance ID pattern: `TalkingmatController_0`, `TalkingmatController_1`, etc.
