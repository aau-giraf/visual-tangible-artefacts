# Class: UserRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/user_repository.dart`

## Overview
The `UserRepository` class provides a centralized interface for performing database operations (CRUD) on `UserDB` objects within the local SQLite database. It encapsulates the data access logic, interacting with the `DatabaseHelper` to execute queries and manage `UserDB` records, supporting both active and soft-deleted user retrieval.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(UserDB user)`
- **Purpose**: Inserts a new `UserDB` record into the 'user' table. If a user with the same ID already exists, it replaces the existing record.
- **Parameters**:
  - `user` (`UserDB`): The user object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row, or the `id` of the replaced row if a conflict occurred.

### `getById(String id)`
- **Purpose**: Retrieves a single `UserDB` record by its `id`, excluding any soft-deleted users.
- **Parameters**:
  - `id` (String): The ID of the user to retrieve.
- **Returns**: `Future<UserDB?>` - The `UserDB` object if found and not soft-deleted, otherwise `null`.

### `getAll()`
- **Purpose**: Retrieves all `UserDB` records from the database, excluding soft-deleted ones.
- **Parameters**: None
- **Returns**: `Future<List<UserDB>>` - A list of all `UserDB` objects, ordered by `username` ascending.

### `update(UserDB user)`
- **Purpose**: Updates an existing `UserDB` record in the database.
- **Parameters**:
  - `user` (`UserDB`): The user object containing updated information. The `id` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and updated).

### `delete(String id)`
- **Purpose**: Performs a soft delete on a `UserDB` record by setting its `is_deleted` flag to `1` and updating its `modified_date`.
- **Parameters**:
  - `id` (String): The ID of the user to soft delete.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and marked as deleted).

### `hardDelete(String id)`
- **Purpose**: Permanently deletes a `UserDB` record from the database. This bypasses the soft delete mechanism.
- **Parameters**:
  - `id` (String): The ID of the user to hard delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `getAllIncludingDeleted()`
- **Purpose**: Retrieves all `UserDB` records from the database, including those marked as soft-deleted.
- **Parameters**: None
- **Returns**: `Future<List<UserDB>>` - A list of all `UserDB` objects, ordered by `username` ascending.

### `deleteAll()`
- **Purpose**: Permanently deletes all `UserDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/user_db.dart`

## Notable Packages
- `sqflite`
