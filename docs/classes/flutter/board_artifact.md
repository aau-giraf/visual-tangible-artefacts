# BoardArtefact

**File:** `Frontend/vta_app/lib/src/ui/widgets/board/board_artifact.dart` (297 lines)

## Purpose

Data model + widget wrapper for an artefact placed on a board. Holds position, size (via `ValueNotifier`), resize handle state, and delegates to the underlying `Artefact` DTO. Contains the resizable content widget (`_BoardArtefactContent`).

## Class: `BoardArtefact`

### Properties
| Property | Type | Description |
|----------|------|-------------|
| `baseContent` | `Widget` | The visual content (image/icon) |
| `position` | `Offset?` | Board coordinates |
| `renderedSize` | `Size?` | Actual rendered pixel size (measured by TalkingMat) |
| `baseArtefact` | `Artefact?` | Underlying DTO |
| `savedArtefactId` | `String?` | Backend instance ID (for persistence + remote sync) |
| `sizeNotifier` | `ValueNotifier<Size>` | Observable size (default 200×200) |
| `showResizeHandle` | `ValueNotifier<bool>` | Whether resize handle is visible |
| `nameVisible` | `bool` | Proxy to `baseArtefact.nameShown` |

### Factory: `BoardArtefact.fromArtefact(artefact, {headers})`
Creates content widget based on artefact data:
1. Has `imageUrl` → `FadeInImage` with `NetworkImage` (authenticated headers) + flutter_logo placeholder
2. No image, has `soundUrl` → speaker icon with play button (creates new `AudioPlayer` on tap)
3. Neither → flutter_logo fallback

### Methods
- `content` getter — returns `_BoardArtefactContent` widget wrapping `baseContent` with size + resize
- `clone({keepPosition})` — deep-ish copy preserving size, nameVisible, optionally position

## Widget: `_BoardArtefactContent` (private StatefulWidget)

### Auto-sizing (`_maybeAutoSizeFromImage`)
On first render, if size is default (200×200) and image URL exists:
- Resolves image via `ImageStream` to get native dimensions
- Classifies as square/landscape/portrait → picks target width (220/260/180)
- Computes proportional height, clamps to min/max (100–500)
- Updates `sizeNotifier` once

### Resize Handle
- Bottom-right drag handle (36px), shown when `showResizeNotifier` is true
- `Listener` on pointer events: proportional resize maintaining aspect ratio
- Width clamped to 100–500px

### Design Notes
- Not a `ChangeNotifier` — uses `ValueNotifier` for size and resize state
- `nameVisible` is a proxy to `baseArtefact.nameShown` (single source of truth)
- Sound-only artefacts create a new `AudioPlayer` per tap (no disposal — potential leak)
