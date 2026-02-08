# Class: SyncMetadataRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/sync_metadata_repository.dart`

## Overview
The `SyncMetadataRepository` class provides a centralized interface for performing database operations on `SyncMetadataDB` objects within the local SQLite database. It specializes in managing synchronization metadata, including tracking `lastSyncDate` and `lastCheckDate` for different entity types (artefacts, boards) per user.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `upsert(SyncMetadataDB metadata)`
- **Purpose**: Inserts a new `SyncMetadataDB` record or updates an existing one if a record with the same `userId` and `entityType` already exists.
- **Parameters**:
  - `metadata` (`SyncMetadataDB`): The sync metadata object to insert or update.
- **Returns**: `Future<int>` - The number of rows affected (1 for insert/update).

### `get(String userId, String entityType)`
- **Purpose**: Retrieves a single `SyncMetadataDB` record for a specific user and entity type.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `entityType` (String): The type of entity (e.g., 'artefact', 'board').
- **Returns**: `Future<SyncMetadataDB?>` - The `SyncMetadataDB` object if found, otherwise `null`.

### `getByUserId(String userId)`
- **Purpose**: Retrieves all `SyncMetadataDB` records for a specific user across all entity types.
- **Parameters**:
  - `userId` (String): The ID of the user.
- **Returns**: `Future<List<SyncMetadataDB>>` - A list of `SyncMetadataDB` objects.

### `getLastSyncDate(String userId, String entityType)`
- **Purpose**: Retrieves the `lastSyncDate` for a specific user and entity type, converting the Unix timestamp to a `DateTime` object.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `entityType` (String): The type of entity.
- **Returns**: `Future<DateTime?>` - The `DateTime` of the last sync, or `null` if no metadata is found.

### `updateLastSyncDate(String userId, String entityType, DateTime syncDate)`
- **Purpose**: Updates the `lastSyncDate` and `lastCheckDate` for a specific user and entity type. If no metadata exists, a new record is created.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `entityType` (String): The type of entity.
  - `syncDate` (`DateTime`): The new synchronization date.
- **Returns**: `Future<void>`

### `updateLastCheckDate(String userId, String entityType)`
- **Purpose**: Updates only the `lastCheckDate` for a specific user and entity type. If no metadata exists, a new record is created with `lastSyncDate` also set to the current time.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `entityType` (String): The type of entity.
- **Returns**: `Future<void>`

### `delete(String userId, String entityType)`
- **Purpose**: Permanently deletes a `SyncMetadataDB` record for a specific user and entity type.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `entityType` (String): The type of entity.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteByUserId(String userId)`
- **Purpose**: Permanently deletes all `SyncMetadataDB` records for a specific user across all entity types.
- **Parameters**:
  - `userId` (String): The ID of the user.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteAll()`
- **Purpose**: Permanently deletes all `SyncMetadataDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/sync_metadata_db.dart`

## Notable Packages
- `sqflite`
