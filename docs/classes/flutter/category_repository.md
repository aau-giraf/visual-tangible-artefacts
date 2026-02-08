# Class: CategoryRepository

**Path:** `Frontend/vta_app/lib/src/database/repositories/category_repository.dart`

## Overview
The `CategoryRepository` class provides a centralized interface for performing database operations (CRUD - Create, Read, Update, Delete) on `CategoryDB` objects within the local SQLite database. It encapsulates the data access logic, interacting with the `DatabaseHelper` to execute queries and manage `CategoryDB` records, including tracking usage metrics.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `_dbHelper` (final `DatabaseHelper`): An instance of `DatabaseHelper` used to interact with the SQLite database.

## Methods

### `insert(CategoryDB category)`
- **Purpose**: Inserts a new `CategoryDB` record into the 'category' table. If a category with the same ID already exists, it replaces the existing record.
- **Parameters**:
  - `category` (`CategoryDB`): The category object to insert.
- **Returns**: `Future<int>` - The `id` of the last inserted row, or the `id` of the replaced row if a conflict occurred.

### `getById(String categoryId)`
- **Purpose**: Retrieves a single `CategoryDB` record by its `categoryId`, excluding any soft-deleted categories.
- **Parameters**:
  - `categoryId` (String): The ID of the category to retrieve.
- **Returns**: `Future<CategoryDB?>` - The `CategoryDB` object if found and not soft-deleted, otherwise `null`.

### `getByUserId(String userId)`
- **Purpose**: Retrieves all `CategoryDB` records belonging to a specific user, excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user whose categories are to be retrieved.
- **Returns**: `Future<List<CategoryDB>>` - A list of `CategoryDB` objects, ordered by `category_index` ascending.

### `getAll()`
- **Purpose**: Retrieves all `CategoryDB` records from the database, excluding soft-deleted ones.
- **Parameters**: None
- **Returns**: `Future<List<CategoryDB>>` - A list of all `CategoryDB` objects, ordered by `category_index` ascending.

### `update(CategoryDB category)`
- **Purpose**: Updates an existing `CategoryDB` record in the database.
- **Parameters**:
  - `category` (`CategoryDB`): The category object containing updated information. The `categoryId` field is used to identify the record to update.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and updated).

### `delete(String categoryId)`
- **Purpose**: Performs a soft delete on a `CategoryDB` record by setting its `is_deleted` flag to `1` and updating its `modified_date`.
- **Parameters**:
  - `categoryId` (String): The ID of the category to soft delete.
- **Returns**: `Future<int>` - The number of rows affected (should be 1 if found and marked as deleted).

### `incrementUsageCount(String categoryId)`
- **Purpose**: Increments the `usage_count` for a specific category and updates its `last_used_date` to the current time.
- **Parameters**:
  - `categoryId` (String): The ID of the category to update.
- **Returns**: `Future<int>` - The number of rows affected.

### `getMostRecentlyUsed(String userId, {int limit = 10})`
- **Purpose**: Retrieves a limited number of the most recently used `CategoryDB` records for a specific user, excluding soft-deleted ones and those never used.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `limit` (int): The maximum number of categories to retrieve (defaults to 10).
- **Returns**: `Future<List<CategoryDB>>` - A list of `CategoryDB` objects, ordered by `last_used_date` descending.

### `getMostUsed(String userId, {int limit = 10})`
- **Purpose**: Retrieves a limited number of the most used `CategoryDB` records for a specific user, based on their `usage_count`, excluding soft-deleted ones.
- **Parameters**:
  - `userId` (String): The ID of the user.
  - `limit` (int): The maximum number of categories to retrieve (defaults to 10).
- **Returns**: `Future<List<CategoryDB>>` - A list of `CategoryDB` objects, ordered by `usage_count` descending.

### `hardDelete(String categoryId)`
- **Purpose**: Permanently deletes a `CategoryDB` record from the database. This bypasses the soft delete mechanism.
- **Parameters**:
  - `categoryId` (String): The ID of the category to hard delete.
- **Returns**: `Future<int>` - The number of rows deleted.

### `deleteAll()`
- **Purpose**: Permanently deletes all `CategoryDB` records from the database.
- **Parameters**: None
- **Returns**: `Future<int>` - The number of rows deleted.

## Internal Imports
- `../database_helper.dart`
- `../models/category_db.dart`

## Notable Packages
- `sqflite`
