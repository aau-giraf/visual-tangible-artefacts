# Class: ArtefactRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/artefact_repository.dart`

## Overview
The `ArtefactRepository` class provides a centralized interface for performing database operations (CRUD - Create, Read, Update, Delete) on `ArtefactDB` objects within the local SQLite database. It encapsulates the data access logic, interacting with the `DatabaseHelper` to execute queries and manage `ArtefactDB` records.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(ArtefactDB artefact)`
- **Purpose**: Inserts a new `ArtefactDB` record into the 'artefact' table. If an artefact with the same ID already exists, it replaces the existing record.
- **Parameters**:
  - `artefact` (`ArtefactDB`): The artefact object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row, or the `id` of the replaced row if a conflict occurred.

### `getById(String artefactId)`
- **Purpose**: Retrieves a single `ArtefactDB` record by its `artefactId`, excluding any soft-deleted artefacts.
- **Parameters**:
  - `artefactId` (String): The ID of the artefact to retrieve.
- **Returns**: `Future<ArtefactDB?>` - The `ArtefactDB` object if found and not soft-deleted, otherwise `null`.

### `getByUserId(String userId)`
- **Purpose**: Retrieves all `ArtefactDB` records belonging to a specific user, excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user whose artefacts are to be retrieved.
- **Returns**: `Future<List<ArtefactDB>>` - A list of `ArtefactDB` objects, ordered by `artefact_index` ascending.

### `getByCategoryId(String categoryId)`
- **Purpose**: Retrieves all `ArtefactDB` records associated with a specific category, excluding soft-deleted ones.
- **Parameters**:
  - `categoryId` (String): The ID of the category whose artefacts are to be retrieved.
- **Returns**: `Future<List<ArtefactDB>>` - A list of `ArtefactDB` objects, ordered by `artefact_index` ascending.

### `getAll()`
- **Purpose**: Retrieves all `ArtefactDB` records from the database, excluding soft-deleted ones.
- **Parameters**: None
- **Returns**: `Future<List<ArtefactDB>>` - A list of all `ArtefactDB` objects, ordered by `artefact_index` ascending.

### `update(ArtefactDB artefact)`
- **Purpose**: Updates an existing `ArtefactDB` record in the database.
- **Parameters**:
  - `artefact` (`ArtefactDB`): The artefact object containing updated information. The `artefactId` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and updated).

### `delete(String artefactId)`
- **Purpose**: Performs a soft delete on an `ArtefactDB` record by setting its `is_deleted` flag to `1` and updating its `modified_date`.
- **Parameters**:
  - `artefactId` (String): The ID of the artefact to soft delete.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and marked as deleted).

### `searchByName(String userId, String searchTerm)`
- **Purpose**: Searches for `ArtefactDB` records belonging to a specific user whose names contain the `searchTerm` (case-insensitive), excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user to search within.
  - `searchTerm` (String): The text to search for within artefact names.
- **Returns**: `Future<List<ArtefactDB>>` - A list of matching `ArtefactDB` objects, ordered by `name` ascending.

### `getByIds(List<String> artefactIds)`
- **Purpose**: Retrieves multiple `ArtefactDB` records by a list of their IDs, excluding soft-deleted ones.
- **Parameters**:
  - `artefactIds` (`List<String>`): A list of artefact IDs to retrieve.
- **Returns**: `Future<List<ArtefactDB>>` - A list of matching `ArtefactDB` objects. Returns an empty list if `artefactIds` is empty.

### `hardDelete(String artefactId)`
- **Purpose**: Permanently deletes an `ArtefactDB` record from the database. This bypasses the soft delete mechanism.
- **Parameters**:
  - `artefactId` (String): The ID of the artefact to hard delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteByCategory(String categoryId)`
- **Purpose**: Performs a soft delete on all `ArtefactDB` records associated with a specific category by setting their `is_deleted` flag to `1` and updating their `modified_date`.
- **Parameters**:
  - `categoryId` (String): The ID of the category whose artefacts are to be soft deleted.
- **Returns**: `Future<int>` - The number of rows affected.

### `deleteAll()`
- **Purpose**: Permanently deletes all `ArtefactDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/artefact_db.dart`

## Notable Packages
- `sqflite`
