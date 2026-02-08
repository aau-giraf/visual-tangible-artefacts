# ArtefactController

**File:** `Frontend/vta_app/lib/src/controllers/artifact_controller.dart` (316 lines)

## Purpose

ChangeNotifier wrapping `ArtifactModel` for artefact and category CRUD. Handles UI feedback (snackbars), delete confirmation dialogs, and category usage tracking.

## Class: `ArtefactController` extends `ChangeNotifier`

### Constructor
`ArtefactController(ArtifactModel model)`

### Exposed State
- `categories` → from model
- `mostUsedCategories` → from model

### Methods

| Method | Description |
|--------|-------------|
| `updateArtifacts({context})` | Fetches all categories via model |
| `updateMostUsedCategories({context, limit})` | Fetches top-N used categories (default 3) |
| `clearUserData()` | Clears model cache, notifies listeners |
| `newCategory(context)` | Shows `AddItemPopup` dialog → posts new category via model |
| `deleteCategory(category, context)` | Confirmation dialog → deletes via model |
| `newArtifact(context, categoryId, {onCreated})` | Shows `AddItemPopup` → posts new artefact, calls `onCreated` callback with result |
| `deleteArtefact(context, artefact)` | Confirmation dialog → deletes via model, returns `bool` |
| `updateArtefact(context, artefact)` | Updates artefact via model (rethrows on error) |
| `updateArtifact(artefact, context)` | Duplicate update method (different signature, swallows errors) |
| `trackCategoryUsage(categoryId)` | Tracks usage count for "most used" feature |

### UI Feedback
- Success/error shown via `GlobalSnackbar.show()` (green/red icons)
- After async gaps: saves `ScaffoldMessengerState` reference before dialog to avoid stale context
- Delete confirmation: Danish dialog ("Er du sikker på du vil slette denne?")

### Design Notes
- All user-facing strings hardcoded in Danish
- Two `updateArt[ie]fact` methods exist with slightly different behavior (one rethrows, one swallows)
- `newArtifact` supports optional `onCreated` callback for post-creation actions
- Token obtained from `GetIt.instance.get<Token>()` on every call
