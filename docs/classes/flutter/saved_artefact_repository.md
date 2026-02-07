# Class: SavedArtefactRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/saved_artefact_repository.dart`

## Overview
The `SavedArtefactRepository` class provides a centralized interface for performing database operations (CRUD - Create, Read, Update, Delete) on `SavedArtefactDB` objects within the local SQLite database. It encapsulates the data access logic, interacting with the `DatabaseHelper` to execute queries and manage `SavedArtefactDB` records, including operations for position, size, and batch inserts.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(SavedArtefactDB savedArtefact)`
- **Purpose**: Inserts a new `SavedArtefactDB` record into the 'saved_artefact' table. If a saved artefact with the same ID already exists, it replaces the existing record.
- **Parameters**:
  - `savedArtefact` (`SavedArtefactDB`): The saved artefact object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row, or the `id` of the replaced row if a conflict occurred.

### `getById(String id)`
- **Purpose**: Retrieves a single `SavedArtefactDB` record by its `id`, excluding any soft-deleted saved artefacts.
- **Parameters**:
  - `id` (String): The ID of the saved artefact to retrieve.
- **Returns**: `Future<SavedArtefactDB?>` - The `SavedArtefactDB` object if found and not soft-deleted, otherwise `null`.

### `getByBoardId(String boardId)`
- **Purpose**: Retrieves all `SavedArtefactDB` records associated with a specific board, excluding soft-deleted ones.
- **Parameters**:
  - `boardId` (String): The ID of the board whose saved artefacts are to be retrieved.
- **Returns**: `Future<List<SavedArtefactDB>>` - A list of `SavedArtefactDB` objects, ordered by `created_date` ascending.

### `getByArtefactId(String artefactId)`
- **Purpose**: Retrieves all `SavedArtefactDB` records that are instances of a specific base artefact, excluding soft-deleted ones.
- **Parameters**:
  - `artefactId` (String): The ID of the base artefact whose saved instances are to be retrieved.
- **Returns**: `Future<List<SavedArtefactDB>>` - A list of `SavedArtefactDB` objects.

### `getAll()`
- **Purpose**: Retrieves all `SavedArtefactDB` records from the database, excluding soft-deleted ones.
- **Parameters**: None
- **Returns**: `Future<List<SavedArtefactDB>>` - A list of all `SavedArtefactDB` objects.

### `update(SavedArtefactDB savedArtefact)`
- **Purpose**: Updates an existing `SavedArtefactDB` record in the database.
- **Parameters**:
  - `savedArtefact` (`SavedArtefactDB`): The saved artefact object containing updated information. The `id` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and updated).

### `updatePosition(String id, double posX, double posY)`
- **Purpose**: Updates the position (`posX`, `posY`) and `modified_date` of a specific `SavedArtefactDB` record.
- **Parameters**:
  - `id` (String): The ID of the saved artefact to update.
  - `posX` (double): The new X-position.
  - `posY` (double): The new Y-position.
- **Returns**: `Future<int>` - The number of rows affected.

### `updateSize(String id, double width, double height)`
- **Purpose**: Updates the size (`width`, `height`) and `modified_date` of a specific `SavedArtefactDB` record.
- **Parameters**:
  - `id` (String): The ID of the saved artefact to update.
  - `width` (double): The new width.
  - `height` (double): The new height.
- **Returns**: `Future<int>` - The number of rows affected.

### `delete(String id)`
- **Purpose**: Performs a soft delete on a `SavedArtefactDB` record by setting its `is_deleted` flag to `1` and updating its `modified_date`.
- **Parameters**:
  - `id` (String): The ID of the saved artefact to soft delete.
- **Returns**: `Future<int>` - The number of rows affected.

### `deleteByBoardId(String boardId)`
- **Purpose**: Performs a soft delete on all `SavedArtefactDB` records associated with a specific board by setting their `is_deleted` flag to `1` and updating their `modified_date`.
- **Parameters**:
  - `boardId` (String): The ID of the board whose saved artefacts are to be soft deleted.
- **Returns**: `Future<int>` - The number of rows affected.

### `hardDelete(String id)`
- **Purpose**: Permanently deletes a `SavedArtefactDB` record from the database. This bypasses the soft delete mechanism.
- **Parameters**:
  - `id` (String): The ID of the saved artefact to hard delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteAll()`
- **Purpose**: Permanently deletes all `SavedArtefactDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

### `insertBatch(List<SavedArtefactDB> savedArtefacts)`
- **Purpose**: Inserts multiple `SavedArtefactDB` records into the database in a single batch operation.
- **Parameters**:
  - `savedArtefacts` (`List<SavedArtefactDB>`): A list of saved artefact objects to insert.
- **Returns**: `Future<void>` - Completes when the batch insertion is done.

## Internal Imports
- `../database_helper.dart`
- `../models/saved_artefact_db.dart`

## Notable Packages
- `sqflite`
