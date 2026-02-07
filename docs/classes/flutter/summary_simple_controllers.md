# Simple Controllers Summary

**Path:** `Frontend/vta_app/lib/src/controllers/`

## Files

| File | Lines | Class | Description |
|------|-------|-------|-------------|
| `board_controller.dart` | 1 | — | Empty file (unused) |
| `linear_board_controller.dart` | 158 | `LinearBoardController` (ChangeNotifier) | Fixed-slot list of `BoardArtefact?`. Manages add (first null slot or shift neighbors), move (swap or shift), remove (set null), and field count resize. Fires `_boardFullCallback` when no slots available. `restoreArtifacts()` for multi-board state loading. |
