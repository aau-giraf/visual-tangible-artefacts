# CategoriesWidget

**File:** `Frontend/vta_app/lib/src/ui/widgets/categories/categories_widget.dart` (623 lines)

## Purpose

Horizontal scrollable category bar at the bottom of the board screen. Shows "most used" categories first (separated by a red divider), then all categories, with an add button. Tapping a category opens a bottom sheet grid of its artefacts for drag-to-board.

## Class: `CategoriesWidget` extends `StatefulWidget`

### Props
- `widgetHeight` — height of category items
- `artefactController` — `ArtefactController` for CRUD + usage tracking
- `onArtifactAdded(BoardArtefact)` — callback when user selects an artefact to add to board

### Category Bar Layout
1. **Most used categories** — fetched via `updateMostUsedCategories()` on init
2. **Red vertical divider**
3. **All categories** — full list from controller
4. **Add button** (+) — opens `AddItemPopup` for new category

### Interactions
- **Tap category** → tracks usage + opens artefact grid bottom sheet
- **Long press category** → opens edit modal (Edit / Delete / Move options)
- **Move mode** — enables `CustomDelayDragStartListener` for reordering (exits on tap outside via `TapRegion`)

### Artefact Grid (`_buildImageGrid`)
- Responsive `GridView`: 3 columns mobile / 4 tablet / 8 desktop
- First cell: add artefact button
- **Tap artefact** → hover animation (scale 1.15, offset) → calls `onArtifactAdded` → closes sheet
- **Long press artefact** → enters deletion mode (red X buttons on each artefact)
- `MouseRegion` for desktop hover support

### Category Edit Modal
- **Edit** → opens `AddItemPopup` pre-filled with category data
- **Delete** → `ArtefactController.deleteCategory()`
- **Move** → enables reorder mode

### Design Notes
- Uses both `Provider` (`AuthState`, `ArtifactState`) and `GetIt` (`ArtefactController`, `Token`) — dual state management patterns
- `_showAddCategoryPopup` and `_showAddArtifactPopup` are unused (superseded by `ArtefactController.newCategory/newArtifact`)
- `ListenableBuilder` on `artefactController` ensures grid rebuilds on CRUD changes
- Hover effect uses animated translate + scale for tactile feedback
