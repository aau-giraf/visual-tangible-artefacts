# Class: SavedBoardRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/saved_board_repository.dart`

## Overview
The `SavedBoardRepository` class provides a centralized interface for performing database operations (CRUD - Create, Read, Update, Delete) on `SavedBoardDB` objects within the local SQLite database. It encapsulates the data access logic, interacting with the `DatabaseHelper` to execute queries and manage `SavedBoardDB` records.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(SavedBoardDB board)`
- **Purpose**: Inserts a new `SavedBoardDB` record into the 'saved_board' table. If a board with the same ID already exists, it replaces the existing record.
- **Parameters**:
  - `board` (`SavedBoardDB`): The saved board object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row, or the `id` of the replaced row if a conflict occurred.

### `getById(String id)`
- **Purpose**: Retrieves a single `SavedBoardDB` record by its `id`, excluding any soft-deleted boards.
- **Parameters**:
  - `id` (String): The ID of the saved board to retrieve.
- **Returns**: `Future<SavedBoardDB?>` - The `SavedBoardDB` object if found and not soft-deleted, otherwise `null`.

### `getByUserId(String userId)`
- **Purpose**: Retrieves all `SavedBoardDB` records belonging to a specific user, excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user whose saved boards are to be retrieved.
- **Returns**: `Future<List<SavedBoardDB>>` - A list of `SavedBoardDB` objects, ordered by `modified_date` descending.

### `getAll()`
- **Purpose**: Retrieves all `SavedBoardDB` records from the database, excluding soft-deleted ones.
- **Parameters**: None
- **Returns**: `Future<List<SavedBoardDB>>` - A list of all `SavedBoardDB` objects, ordered by `modified_date` descending.

### `update(SavedBoardDB board)`
- **Purpose**: Updates an existing `SavedBoardDB` record in the database.
- **Parameters**:
  - `board` (`SavedBoardDB`): The saved board object containing updated information. The `id` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and updated).

### `delete(String id)`
- **Purpose**: Performs a soft delete on a `SavedBoardDB` record by setting its `is_deleted` flag to `1` and updating its `modified_date`.
- **Parameters**:
  - `id` (String): The ID of the saved board to soft delete.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and marked as deleted).

### `searchByName(String userId, String searchTerm)`
- **Purpose**: Searches for `SavedBoardDB` records belonging to a specific user whose names contain the `searchTerm` (case-insensitive), excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user to search within.
  - `searchTerm` (String): The text to search for within board names.
- **Returns**: `Future<List<SavedBoardDB>>` - A list of matching `SavedBoardDB` objects, ordered by `name` ascending.

### `getRecentBoards(String userId, {int limit = 10})`
- **Purpose**: Retrieves a limited number of the most recently modified `SavedBoardDB` records for a specific user, excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user whose recent boards are to be retrieved.
  - `limit` (int): The maximum number of recent boards to retrieve (defaults to 10).
- **Returns**: `Future<List<SavedBoardDB>>` - A list of `SavedBoardDB` objects, ordered by `modified_date` descending.

### `hardDelete(String id)`
- **Purpose**: Permanently deletes a `SavedBoardDB` record from the database. This bypasses the soft delete mechanism.
- **Parameters**:
  - `id` (String): The ID of the saved board to hard delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteAll()`
- **Purpose**: Permanently deletes all `SavedBoardDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/saved_board_db.dart`

## Notable Packages
- `sqflite`
