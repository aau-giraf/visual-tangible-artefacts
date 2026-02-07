# Feature: Board System

## Summary

The Board System lets users place artefacts onto visual boards in two layout modes: **TalkingMat** (free-form drag-and-drop grid) and **LinearBoard** (fixed-slot sequential). Boards are persisted server-side via `BoardsController` (`api/Boards`) and `SavedArtefactsController` (`api/Boards/{boardId}/SavedArtefacts`), each board storing a list of `SavedArtefact` records with position/size data. On the Flutter side, `ArtifactBoardController` manages multi-board state (create/switch/delete boards), delegating layout operations to `TalkingmatController` (a `ValueNotifier<List<BoardArtefact>>`) and `LinearBoardController` (a `ChangeNotifier` with fixed-slot list). `BoardLayoutService` wraps all REST calls for board CRUD and artefact placement. The board can also play all artefact sounds sequentially. The `ArtifactBoardScreen` renders the active board and the category drawer.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class BoardsController {
            +GetBoards() ActionResult~List~BoardGetDTO~~
            +GetBoardsList() ActionResult~List~BoardListItemDTO~~
            +GetBoard(boardId) ActionResult~BoardGetDTO~
            +PostBoard(body) IActionResult
            +PatchBoard(BoardPatchDTO) IActionResult
            +UpdateBoard(boardId, SaveBoardRequestDTO) ActionResult~BoardLayoutResponseDTO~
            +UpdateArtefactLayout(boardId, UpdateArtefactLayoutDTO) IActionResult
            +RemoveArtefactFromBoard(boardId, savedArtefactId) IActionResult
            +ClearBoard(boardId) IActionResult
            +DeleteBoard(boardId) IActionResult
        }
        class SavedArtefactsController {
            +UpdateArtefactLayout(boardId, UpdateArtefactLayoutDTO) IActionResult
            +RemoveArtefactFromBoard(boardId, savedArtefactId) IActionResult
            +ClearBoard(boardId) IActionResult
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class ArtifactBoardController {
            +availableBoards List~Board~
            +activeBoard Board
            +showDirectional bool
            +talkingmatController TalkingmatController
            +linearBoardController LinearBoardController
            +isPlayingAllSounds bool
            +createBoard(title) void
            +deleteBoard(boardId) void
            +switchBoard(boardId) void
            +switchCurrentBoard() void
            +getCurrentBoardStatus() void
            +addArtifactToCurrentBoard(artifact) void
            +playAllArtefactSounds() Future~void~
            +updateNotifyView(callback) void
        }
        class TalkingmatController {
            +value List~BoardArtefact~
            +add(artifact) void
            +remove(artifact) bool
            +removeAt(index) BoardArtefact
            +clear() void
        }
        class LinearBoardController {
            +artifacts List~BoardArtefact?~
            +fieldCount int
            +setFieldCount(count) void
            +addArtifact(artifact, index?) void
            +moveArtifact(currentId, newId) void
            +removeArtifact(index) void
            +removeAllArtifacts() void
            +restoreArtifacts(list) void
        }
        class BoardLayoutService {
            +getBoards() Future~List~BoardLayoutResponse~?~
            +getBoard(boardId) Future~BoardLayoutResponse?~
            +saveBoard(request) Future~BoardLayoutResponse?~
            +updateBoard(boardId, request) Future~BoardLayoutResponse?~
            +updateArtefactLayout(boardId, request) Future~bool~
            +deleteBoard(boardId) Future~bool~
            +deleteSavedArtefact(boardId, id) Future~bool~
            +deleteAllSavedArtefacts(boardId) Future~bool~
        }
        class ArtifactBoardScreen {
            «StatefulWidget»
        }
    }

    %% ── Relationships ────────────────────────────
    ArtifactBoardController --> TalkingmatController : owns
    ArtifactBoardController --> LinearBoardController : owns
    ArtifactBoardController --> BoardLayoutService : board CRUD
    ArtifactBoardScreen --> ArtifactBoardController : uses (via GetIt)

    BoardLayoutService ..> BoardsController : HTTP GET/POST/PUT/PATCH/DELETE
    TalkingmatController --|> ValueNotifier : extends

    BoardsController --> SavedArtefactsController : overlapping routes
```

---

## Sequence Diagram — Save Board Layout (PUT)

```mermaid
sequenceDiagram
    actor User
    participant Screen as ArtifactBoardScreen
    participant ABC as ArtifactBoardController
    participant BLS as BoardLayoutService
    participant AP as ApiProvider
    participant BC as BoardsController (Backend)
    participant DB as MySQL

    User->>Screen: Arrange artefacts on board
    Screen->>ABC: board state changes (add/move/remove)
    ABC->>ABC: Update talkingmatController / linearBoardController
    Note over ABC: On save/switch/navigate away
    ABC->>BLS: updateBoard(boardId, SaveBoardRequest)
    BLS->>AP: putAsJson("Boards/{boardId}", body)
    AP->>BC: PUT /api/Boards/{boardId}
    BC->>DB: Upsert SavedArtefacts (position, size, artefactId)
    BC->>DB: Update SavedBoard metadata
    DB-->>BC: OK
    BC-->>AP: 200 BoardLayoutResponseDTO
    AP-->>BLS: Response
    BLS-->>ABC: BoardLayoutResponse
```

---

## Sequence Diagram — Load Boards on Screen Entry

```mermaid
sequenceDiagram
    participant Screen as ArtifactBoardScreen
    participant ABC as ArtifactBoardController
    participant BLS as BoardLayoutService
    participant AP as ApiProvider
    participant BC as BoardsController (Backend)
    participant DB as MySQL

    Screen->>ABC: initState → retrieve from GetIt
    ABC->>BLS: getBoards()
    BLS->>AP: fetchAsJson("Boards")
    AP->>BC: GET /api/Boards
    BC->>DB: SELECT SavedBoards WHERE UserId = jwt.id<br/>INCLUDE SavedArtefacts → Artefact
    DB-->>BC: List~SavedBoard~
    BC-->>AP: 200 List~BoardGetDTO~
    AP-->>BLS: Response
    BLS-->>ABC: List~BoardLayoutResponse~
    ABC->>ABC: Set availableBoards, activeBoard = first
    ABC->>ABC: _loadBoardState(activeBoard)
    ABC->>TalkingmatController: value = talkingMatArtifacts
    ABC->>LinearBoardController: restoreArtifacts(linearArtifacts)
    ABC->>Screen: notifyView()
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **BoardsController is a god class (759 LOC)** | 🔴 Critical | Handles board CRUD, artefact layout updates, board clearing, snapshot management. Artefact-layout operations should live in `SavedArtefactsController` exclusively. |
| 2 | **Duplicate endpoints across controllers** | 🔴 Critical | `UpdateArtefactLayout`, `RemoveArtefactFromBoard`, and `ClearBoard` exist in **both** `BoardsController` and `SavedArtefactsController` with nearly identical implementations. One set should be removed. |
| 3 | **ArtifactBoardController (413 LOC) has too many responsibilities** | 🟠 High | Manages multi-board state, two layout modes, settings sync, and sound playback. Split sound playback into a `BoardAudioService` and multi-board management into a `BoardManager`. |
| 4 | **Inconsistent DI for ArtifactBoardController** | 🟠 High | Registered in GetIt as a singleton by string key `'ArtifactBoardController'`, but also passed around as constructor parameter. Choose one pattern. |
| 5 | **board_controller.dart is empty** | 🟡 Medium | File exists but is completely empty — should be deleted to avoid confusion. |
| 6 | **SaveBoardRequest sent as full board state** | 🟡 Medium | Every save sends the complete artefact list (PUT semantics). For large boards with many artefacts, a PATCH-based delta approach would be more efficient and reduce conflict risk. |
| 7 | **No optimistic UI updates** | 🟡 Medium | Board operations wait for server response before updating UI. For local actions (add/remove artefact), apply optimistically and reconcile on server response. |
