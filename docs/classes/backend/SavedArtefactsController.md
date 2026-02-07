# Class: SavedArtefactsController

**Path:** `Backend/VTA.API/Controllers/SavedArtefactsController.cs`

## Overview
The `SavedArtefactsController` is an API controller dedicated to managing `SavedArtefact` instances on user-owned boards. It provides endpoints for updating the layout (position and size) of specific saved artefacts, removing individual artefacts from a board, and clearing all artefacts from a board. All endpoints are protected by JWT authentication.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for accessing saved boards and artefacts.

## Constructor

### `SavedArtefactsController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `SavedArtefactsController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with `SavedBoard` and `SavedArtefact` data.

## Methods

### `UpdateArtefactLayout(string boardId, [FromBody] UpdateArtefactLayoutDTO request)`
- **Route**: `PATCH api/Boards/{boardId}/SavedArtefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Updates the position and size of a specific `SavedArtefact` instance on a given board. It explicitly requires a `SavedArtefactId` to prevent accidental updates of unintended instances.
- **Parameters**:
  - `boardId` (string): The ID of the board containing the saved artefact.
  - `request` (`UpdateArtefactLayoutDTO`): An object containing the `SavedArtefactId` and the new position (`PosX`, `PosY`), width (`Width`), and height (`Height`) of the artefact.
- **Returns**: `IActionResult`
  - `200 OK`: On successful update or if no changes were needed.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
  - `400 Bad Request`: If `SavedArtefactId` is missing from the request or the `SavedArtefact` cannot be found on the board.
  - `500 Internal Server Error`: For database or other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board existence and ownership.
  - Attempts to find the specific `SavedArtefact` using `request.SavedArtefactId` and `boardId`.
  - If `SavedArtefact` is not found (e.g., `SavedArtefactId` is null/empty or invalid), returns a `400 Bad Request` because PATCH is intended for existing instances.
  - Checks if the new layout data is different from the current. If changes exist, updates `PosX`, `PosY`, `Width`, `Height` and the `ModifiedDate` of the parent board.
  - Saves changes to the database.

### `RemoveArtefactFromBoard(string boardId, string savedArtefactId)`
- **Route**: `DELETE api/Boards/{boardId}/SavedArtefacts/{savedArtefactId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Removes a specific `SavedArtefact` instance from a board.
- **Parameters**:
  - `boardId` (string): The ID of the board from which to remove the `SavedArtefact`.
  - `savedArtefactId` (string): The ID of the `SavedArtefact` instance to remove.
- **Returns**: `IActionResult`
  - `200 OK`: On successful removal.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board or the `SavedArtefact` is not found or not owned by the user.
  - `500 Internal Server Error`: For database or other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board existence and ownership.
  - Finds the specific `SavedArtefact` to remove within that board.
  - Removes the `SavedArtefact` from the context.
  - Updates the `ModifiedDate` of the parent board.
  - Saves changes to the database.

### `ClearBoard(string boardId)`
- **Route**: `DELETE api/Boards/{boardId}/SavedArtefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Removes all `SavedArtefact` instances from a specified board, effectively clearing its layout without deleting the board itself. It also deletes associated "Session-Artefact"s if they were created specifically for this user and are no longer referenced.
- **Parameters**:
  - `boardId` (string): The ID of the board to clear.
- **Returns**: `IActionResult`
  - `200 OK`: On successful clearing.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the board is not found or not owned by the user.
  - `500 Internal Server Error`: For database or other unhandled exceptions.
- **Functionality**:
  - Extracts `userId` from JWT and verifies board existence and ownership.
  - Removes all `SavedArtefact`s associated with the board from the context.
  - Identifies `ArtefactId`s that were on this board and were categorized as "Session-Artefact" (temporary artefacts). These temporary artefacts are also removed from the `Artefact` table.
  - Updates the `ModifiedDate` of the parent board.
  - Saves all changes to the database.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
