# Class: SyncController

**Path:** `Backend/VTA.API/Controllers/SyncController.cs`

## Overview
The `SyncController` is an API controller dedicated to handling data synchronization requests for authenticated users. It provides endpoints to query for changes in artefacts and boards since a specified date, allowing client applications to efficiently update their local data. All endpoints are protected by JWT authentication.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for accessing artefact and board data.

## Constructor

### `SyncController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `SyncController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with artefact and board data.

## Methods

### `GetChanges([FromQuery] DateTime since)`
- **Route**: `GET api/Sync/changes`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a comprehensive list of all changed artefacts and boards for the current user since a specified `DateTime`.
- **Parameters**:
  - `since` (`DateTime`): An ISO 8601 formatted date string indicating the point in time from which to fetch changes.
- **Returns**: `ActionResult<SyncResponseDTO>`
  - `200 OK`: Returns a `SyncResponseDTO` containing a list of `FileChangeDTO`s, the current `CheckDate`, and the `TotalChanges` count.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `Artefacts` where `UserId` matches and `ModifiedDate` is after `since`.
  - Queries `SavedBoards` where `UserId` matches and `ModifiedDate` is after `since`.
  - Maps both changed artefacts and boards to `FileChangeDTO`s, constructing image and sound URLs as appropriate.
  - Combines and sorts the `FileChangeDTO`s by `ModifiedDate` (descending).
  - Returns a `SyncResponseDTO` with the collected changes.

### `GetChangedArtefacts([FromQuery] DateTime since)`
- **Route**: `GET api/Sync/artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a list of only the changed artefacts for the current user since a specified `DateTime`.
- **Parameters**:
  - `since` (`DateTime`): An ISO 8601 formatted date string.
- **Returns**: `ActionResult<IEnumerable<FileChangeDTO>>`
  - `200 OK`: Returns a list of `FileChangeDTO`s representing the changed artefacts.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `Artefacts` where `UserId` matches and `ModifiedDate` is after `since`.
  - Maps changed artefacts to `FileChangeDTO`s.
  - Returns the list of `FileChangeDTO`s.

### `GetChangedBoards([FromQuery] DateTime since)`
- **Route**: `GET api/Sync/boards`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a list of only the changed boards for the current user since a specified `DateTime`.
- **Parameters**:
  - `since` (`DateTime`): An ISO 8601 formatted date string.
- **Returns**: `ActionResult<IEnumerable<FileChangeDTO>>`
  - `200 OK`: Returns a list of `FileChangeDTO`s representing the changed boards.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Queries `SavedBoards` where `UserId` matches and `ModifiedDate` is after `since`.
  - Maps changed boards to `FileChangeDTO`s.
  - Returns the list of `FileChangeDTO`s.

### `GetChangeSummary([FromQuery] DateTime since)`
- **Route**: `GET api/Sync/summary`
- **Authorization**: `[Authorize]`
- **Purpose**: Provides a summary count of changed artefacts and boards for the current user since a specified `DateTime`.
- **Parameters**:
  - `since` (`DateTime`): An ISO 8601 formatted date string.
- **Returns**: `ActionResult<SyncSummaryDTO>`
  - `200 OK`: Returns a `SyncSummaryDTO` with counts of artefact changes, board changes, total changes, and the current `CheckDate`.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Counts `Artefacts` where `UserId` matches and `ModifiedDate` is after `since`.
  - Counts `SavedBoards` where `UserId` matches and `ModifiedDate` is after `since`.
  - Returns a `SyncSummaryDTO` with the calculated counts and the current `CheckDate`.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
