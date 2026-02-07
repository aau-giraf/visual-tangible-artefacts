# BoardLayoutService

**File:** `Frontend/vta_app/lib/src/services/board_layout_service.dart` (181 lines)

## Purpose

API client for board layout CRUD operations. Manages saved boards, artefact positioning, and board cleanup via the `Users/Boards` endpoints.

## Class: `BoardLayoutService`

### Dependencies (injectable, defaults via GetIt)
`ApiProvider`, `Token`

### Methods

| Method | Endpoint | Description |
|--------|----------|-------------|
| `getBoards()` | GET `Users/Boards` | List all saved boards → `List<BoardLayoutResponse>?` |
| `getBoard(boardId)` | GET `Users/Boards/{id}` | Get single board |
| `saveBoard(request)` | POST `Users/Boards` | Create new board (expects 201) |
| `updateBoard(boardId, request)` | PUT `Users/Boards/{id}` | Replace board layout |
| `updateArtefactLayout(boardId, request)` | PATCH `Users/Boards/{id}/artefacts` | Update single artefact position/size |
| `deleteBoard(boardId)` | DELETE `Users/Boards/{id}` | Delete board |
| `deleteSavedArtefact(boardId, savedArtefactId)` | DELETE `Users/Boards/{id}/artefacts/{saId}` | Remove artefact from board |
| `deleteAllSavedArtefacts(boardId)` | DELETE `Users/Boards/{id}/artefacts` | Clear all artefacts from board |

### Design Notes
- Straightforward CRUD wrapper — no caching, no local state
- Uses `board_layout.dart` DTOs: `SaveBoardRequest`, `BoardLayoutResponse`, `UpdateArtefactLayoutRequest`
- All methods return `null`/`false` on error (swallowed exceptions)
