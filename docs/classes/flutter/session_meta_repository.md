# Class: SessionMetaRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/session_meta_repository.dart`

## Overview
The `SessionMetaRepository` class provides a centralized interface for performing database operations (CRUD) on `SessionMetaDB` objects within the local SQLite database. It manages records related to user sessions, including their status (dirty/synced), and provides methods for retrieving and updating this metadata.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(SessionMetaDB sessionMeta)`
- **Purpose**: Inserts a new session meta record into the 'session_meta' table.
- **Parameters**:
  - `sessionMeta` (`SessionMetaDB`): The session meta object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row.

### `getById(int id)`
- **Purpose**: Retrieves a single `SessionMetaDB` record by its primary key ID.
- **Parameters**:
  - `id` (int): The primary key ID of the session meta record.
- **Returns**: `Future<SessionMetaDB?>` - The `SessionMetaDB` object if found, otherwise `null`.

### `getBySessionId(String sessionId)`
- **Purpose**: Retrieves a single `SessionMetaDB` record by its `sessionId`.
- **Parameters**:
  - `sessionId` (String): The session ID of the record to retrieve.
- **Returns**: `Future<SessionMetaDB?>` - The `SessionMetaDB` object if found, otherwise `null`.

### `getByBoardId(String boardId)`
- **Purpose**: Retrieves all `SessionMetaDB` records associated with a specific board.
- **Parameters**:
  - `boardId` (String): The ID of the board whose session metadata is to be retrieved.
- **Returns**: `Future<List<SessionMetaDB>>` - A list of `SessionMetaDB` objects, ordered by `started_at` descending.

### `getByUserId(String userId)`
- **Purpose**: Retrieves all `SessionMetaDB` records associated with a specific user.
- **Parameters**:
  - `userId` (String): The ID of the user whose session metadata is to be retrieved.
- **Returns**: `Future<List<SessionMetaDB>>` - A list of `SessionMetaDB` objects, ordered by `started_at` descending.

### `getDirtySessions()`
- **Purpose**: Retrieves all `SessionMetaDB` records that are marked as dirty (`is_dirty = 1`), indicating unsynced changes.
- **Parameters**: None
- **Returns**: `Future<List<SessionMetaDB>>` - A list of dirty `SessionMetaDB` objects, ordered by `started_at` ascending.

### `getAll()`
- **Purpose**: Retrieves all `SessionMetaDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<List<SessionMetaDB>>` - A list of all `SessionMetaDB` objects, ordered by `started_at` descending.

### `update(SessionMetaDB sessionMeta)`
- **Purpose**: Updates an existing `SessionMetaDB` record in the database.
- **Parameters**:
  - `sessionMeta` (`SessionMetaDB`): The session meta object containing updated information. The `id` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected.

### `markAsSynced(int id)`
- **Purpose**: Marks a `SessionMetaDB` record as synced by setting its `is_dirty` flag to `0` and updating its `last_synced_at` timestamp.
- **Parameters**:
  - `id` (int): The primary key ID of the session meta record to mark as synced.
- **Returns**: `Future<int>` - The number of rows affected.

### `markAsDirty(int id)`
- **Purpose**: Marks a `SessionMetaDB` record as dirty by setting its `is_dirty` flag to `1`.
- **Parameters**:
  - `id` (int): The primary key ID of the session meta record to mark as dirty.
- **Returns**: `Future<int>` - The number of rows affected.

### `delete(int id)`
- **Purpose**: Permanently deletes a `SessionMetaDB` record from the database by its primary key ID.
- **Parameters**:
  - `id` (int): The primary key ID of the session meta record to delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteByBoardId(String boardId)`
- **Purpose**: Permanently deletes all `SessionMetaDB` records associated with a specific board.
- **Parameters**:
  - `boardId` (String): The ID of the board whose session metadata records are to be deleted.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteOldSyncedSessions(int olderThanTimestamp)`
- **Purpose**: Deletes synced `SessionMetaDB` records (`is_dirty = 0`) that are older than a specified timestamp.
- **Parameters**:
  - `olderThanTimestamp` (int): A Unix timestamp (in seconds). Sessions synced before this time will be deleted.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteAll()`
- **Purpose**: Permanently deletes all `SessionMetaDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/session_meta_db.dart`

## Notable Packages
- `sqflite`
