# Class: BoardsController

**Path:** `Backend/VTA.API/Controllers/BoardsController.cs`

## Overview
The `BoardsController` is an API controller dedicated to managing saved boards and their associated artefacts for authenticated users. It provides comprehensive functionality including listing, retrieving, creating, updating (both metadata and layout), and deleting boards. All endpoints are protected by JWT authentication.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for accessing saved boards and artefacts.

## Constructor

### `BoardsController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `BoardsController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with board and artefact data.

## Methods

### `GetBoards()`
- **Route**: `GET api/Boards`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves all saved boards, including their embedded `SavedArtefacts` and original `Artefact` details, that belong to the authenticated user.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<BoardGetDTO>>`
  - `200 OK`: Returns a collection of `BoardGetDTO` objects.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `SavedBoards` belonging to the user, eagerly loading `SavedArtefacts` and their `Artefact` details.
  - Orders boards by `ModifiedDate` or `CreatedDate` descending.
  - Maps `SavedBoard` entities to `BoardGetDTO`s, constructing `SnapshotUrl`.

### `GetBoardsList()`
- **Route**: `GET api/Boards/list`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a lightweight list of boards (ID, name, thumbnail) for the authenticated user, suitable for displaying in a list.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<BoardListItemDTO>>`
  - `200 OK`: Returns a collection of `BoardListItemDTO` objects.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `SavedBoards` belonging to the user, ordering them.
  - Maps `SavedBoard` entities to `BoardListItemDTO`s, constructing `SnapshotUrl`.

### `GetBoard(string boardId)`
- **Route**: `GET api/Boards/{boardId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a specific board with all its saved artefacts and their layout information.
- **Parameters**:
  - `boardId` (string): The unique identifier of the board to retrieve.
- **Returns**: `ActionResult<BoardGetDTO>`
  - `200 OK`: Returns a `BoardLayoutResponseDTO` for the specified board.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `SavedBoards` by `boardId` and `userId`, including `SavedArtefacts` and their nested `Artefact` details.
  - Maps the found `SavedBoard` to a `BoardLayoutResponseDTO`, converting `SavedArtefact` details into `BoardArtefactLayoutDTO`s.

### `PostBoard([FromBody] JsonElement body)`
- **Route**: `POST api/Boards`
- **Authorization**: `[Authorize]`
- **Purpose**: Creates a new board for the authenticated user. This endpoint intelligently handles two different DTO shapes: a simple `BoardPostDTO` (name only) or a richer `SaveBoardRequestDTO` (name and initial artefact layouts).
- **Parameters**:
  - `body` (`JsonElement`): The raw JSON request body, which is dynamically deserialized based on its content.
- **Returns**: `IActionResult`
  - `201 CreatedAtAction`: On successful creation of a board with artefacts (returns `BoardLayoutResponseDTO`).
  - `200 OK`: On successful creation of a simple board (returns an anonymous object with basic board info).
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `400 Bad Request`: If the DTO is invalid or an artefact in the layout does not exist or belong to the user.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Inspects the `JsonElement` to determine if it contains an "Artefacts" property, indicating a `SaveBoardRequestDTO`.
  - **If `SaveBoardRequestDTO`**:
    - Deserializes to `SaveBoardRequestDTO`.
    - Uses a database transaction and execution strategy for atomicity.
    - Creates a new `SavedBoard`.
    - Iterates through `Artefacts`, checks if each artefact exists and belongs to the user, creates `SavedArtefact` entries, clamps position/size floats, and stores `ArtefactId`s and `SavedArtefactId`s as serialized JSON on the `SavedBoard`.
    - Commits the transaction and returns a `BoardLayoutResponseDTO`.
  - **If `BoardPostDTO` (fallback)**:
    - Deserializes to `BoardPostDTO`.
    - Creates a simple `SavedBoard` with only a name.
    - Saves to the database and returns basic board info.

### `PatchBoard([FromBody] BoardPatchDTO boardPatchDTO)`
- **Route**: `PATCH api/Boards`
- **Authorization**: `[Authorize]`
- **Purpose**: Partially updates a board's metadata (name, snapshot path).
- **Parameters**:
  - `boardPatchDTO` (`BoardPatchDTO`): An object containing the fields to be updated.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Finds the `SavedBoard` by its ID and `userId`.
  - Updates `Name` and `SnapshotPath` if provided in the DTO.
  - Sets `ModifiedDate` to `DateTime.UtcNow`.
  - Marks the entity as `Modified` and saves changes, handling `DbUpdateConcurrencyException`.

### `UpdateBoard(string boardId, [FromBody] SaveBoardRequestDTO request)`
- **Route**: `PUT api/Boards/{boardId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Updates an existing board, replacing its name and entire collection of artefacts and their layouts with the provided `SaveBoardRequestDTO`.
- **Parameters**:
  - `boardId` (string): The ID of the board to update.
  - `request` (`SaveBoardRequestDTO`): The new name and complete list of artefact layouts.
- **Returns**: `ActionResult<BoardLayoutResponseDTO>`
  - `200 OK`: Returns the updated `BoardLayoutResponseDTO`.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
  - `400 Bad Request`: If an artefact in the request does not exist or belong to the user.
  - `500 Internal Server Error`: For database or other unhandled exceptions, including a specific message if a database schema migration is needed.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board ownership.
  - Uses a database transaction and execution strategy.
  - Updates the board's `Name` and `ModifiedDate`.
  - **Replaces all `SavedArtefacts`**: Existing `SavedArtefacts` are removed (or logic to preserve some is commented out) and new `SavedArtefact` instances are created based on the `request.Artefacts` list.
  - Validates that each artefact referenced exists and belongs to the user.
  - Updates `ArtefactIds` and `SavedArtefactIds` JSON fields on the `SavedBoard`.
  - Saves changes and commits the transaction.

### `UpdateArtefactLayout(string boardId, [FromBody] UpdateArtefactLayoutDTO request)`
- **Route**: `PATCH api/Boards/{boardId}/artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Updates the position, size, and/or `NameVisible` status of a single artefact on a specific board. If the artefact is not yet on the board (or not identified by `SavedArtefactId`), it will be added.
- **Parameters**:
  - `boardId` (string): The ID of the board.
  - `request` (`UpdateArtefactLayoutDTO`): The layout data for the artefact to update or add.
- **Returns**: `IActionResult`
  - `200 OK`: On successful update or addition.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found.
  - `400 Bad Request`: If the referenced artefact does not exist or belong to the user.
  - `500 Internal Server Error`: For other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Verifies board existence and ownership.
  - Attempts to find an existing `SavedArtefact` instance by `SavedArtefactId` or `ArtefactId`.
  - **If `SavedArtefact` not found**:
    - Verifies that the `ArtefactId` in the request corresponds to an existing, owned artefact.
    - Creates a new `SavedArtefact` instance and adds it to the board.
    - Updates the `ArtefactIds` and `SavedArtefactIds` JSON fields on the `SavedBoard`.
  - **If `SavedArtefact` found**:
    - Updates its `PosX`, `PosY`, `Width`, `Height` properties.
  - Updates the `board.ModifiedDate`.
  - Saves all changes to the database.

### `RemoveArtefactFromBoard(string boardId, string savedArtefactId)`
- **Route**: `DELETE api/Boards/{boardId}/artefacts/{savedArtefactId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Removes a specific `SavedArtefact` instance from a board.
- **Parameters**:
  - `boardId` (string): The ID of the board from which to remove the artefact.
  - `savedArtefactId` (string): The ID of the `SavedArtefact` instance to remove.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful removal.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board or the saved artefact on the board is not found.
  - `500 Internal Server Error`: For other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board ownership.
  - Finds the `SavedArtefact` to remove.
  - Removes the `SavedArtefact` from the context.
  - Re-serializes the `ArtefactIds` and `SavedArtefactIds` JSON fields on the `SavedBoard` to reflect the removal.
  - Updates `board.ModifiedDate` and saves changes.

### `ClearBoard(string boardId)`
- **Route**: `DELETE api/Boards/{boardId}/artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Removes all `SavedArtefact` instances from a specified board, effectively clearing its layout without deleting the board itself.
- **Parameters**:
  - `boardId` (string): The ID of the board to clear.
- **Returns**: `IActionResult`
  - `200 OK`: With a success message.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
  - `500 Internal Server Error`: For other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board ownership.
  - Removes all `SavedArtefact`s associated with the board.
  - Clears the `ArtefactIds` and `SavedArtefactIds` JSON fields on the `SavedBoard`.
  - Updates `board.ModifiedDate` and saves changes.

### `DeleteBoard(string boardId)`
- **Route**: `DELETE api/Boards/{boardId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Deletes a board and all its associated `SavedArtefact` instances.
- **Parameters**:
  - `boardId` (string): The ID of the board to delete.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deletion.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board ownership.
  - Removes all `SavedArtefact`s associated with the board.
  - Removes the `SavedBoard` itself.
  - Saves changes to the database.

### `BoardExists(string id)` (private)
- **Purpose**: Checks if a board with the given ID exists in the database.
- **Parameters**:
  - `id` (string): The board ID to check.
- **Returns**: `bool` - `true` if a board with the ID exists, `false` otherwise.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `System.Text.Json`
