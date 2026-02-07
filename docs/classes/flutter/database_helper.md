# Class: DatabaseHelper

**Path:** `Frontend/vta_app/lib/src/database/database_helper.dart`

## Overview
The `DatabaseHelper` class is a singleton responsible for managing the local SQLite database for the VTA Flutter application. It ensures that there's only one instance of the database connection throughout the app, handles database creation (`onCreate`) with defined table schemas, and manages schema upgrades (`onUpgrade`). It also provides methods to open, close, and delete the database.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `instance` (static final `DatabaseHelper`): The singleton instance of `DatabaseHelper`.
- `_database` (static `Database?`): A static nullable `Database` instance, lazily initialized.

## Constructor

### `DatabaseHelper._init()` (Private Named Constructor)
- **Purpose**: A private constructor that prevents direct instantiation of `DatabaseHelper` from outside the class, enforcing the singleton pattern.

## Methods

### `get database`
- **Purpose**: Provides asynchronous access to the `Database` instance. If the database has not been initialized yet, it calls `_initDB` to create and open it.
- **Returns**: `Future<Database>` - The initialized SQLite database instance.

### `_initDB(String filePath)` (Private)
- **Purpose**: Initializes and opens the SQLite database.
- **Parameters**:
  - `filePath` (String): The name of the database file (e.g., 'vta.db').
- **Returns**: `Future<Database>` - The opened `Database` instance.
- **Functionality**:
  - Determines the platform-specific path for the database file using `getDatabasesPath()` and `join()`.
  - Opens the database, specifying the `version` (currently 2), `onCreate` callback (`_createDB`), and `onUpgrade` callback (`_onUpgrade`).

### `_createDB(Database db, int version)` (Private)
- **Purpose**: Executes SQL `CREATE TABLE` statements to set up the initial database schema. This method is called only when the database is first created.
- **Parameters**:
  - `db` (`Database`): The database instance.
  - `version` (int): The current database version.
- **Functionality**:
  - Creates the `user` table with columns for `id`, `name`, `username`, `name_visible`, `field_count`, `modified_date`, and `is_deleted`.
  - Creates the `category` table with columns for `category_id`, `category_index`, `user_id`, `name`, `image_path`, `modified_date`, `usage_count`, `last_used_date`, and `is_deleted`.
  - Creates the `artefact` table with columns for `artefact_id`, `artefact_index`, `user_id`, `category_id`, `image_path`, `sound_path`, `modified_date`, `name`, `name_shown`, and `is_deleted`.
  - Creates the `saved_board` table with columns for `id`, `name`, `user_id`, `saved_artefact_ids`, `artefact_ids`, `snapshot_path`, `created_date`, `modified_date`, and `is_deleted`.
  - Creates the `saved_artefact` table with columns for `id`, `artefact_id`, `board_id`, `pos_x`, `pos_y`, `width`, `height`, `created_date`, `modified_date`, `name_visible`, and `is_deleted`.
  - Creates the `session_meta` table with columns for `id`, `session_id`, `board_id`, `user_id`, `started_at`, `last_synced_at`, and `is_dirty`.
  - Creates the `sync_metadata` table with columns for `id`, `user_id`, `entity_type`, `last_sync_date`, and `last_check_date`, ensuring `UNIQUE(user_id, entity_type)`.

### `_onUpgrade(Database db, int oldVersion, int newVersion)` (Private)
- **Purpose**: Handles database schema upgrades when the database version changes.
- **Parameters**:
  - `db` (`Database`): The database instance.
  - `oldVersion` (int): The previous database version.
  - `newVersion` (int): The new database version.
- **Functionality**:
  - If `oldVersion` is less than 2, it creates the `sync_metadata` table (which was introduced in version 2) if it does not already exist.

### `close()`
- **Purpose**: Closes the current database connection and nullifies the `_database` instance.
- **Returns**: `Future<void>`

### `deleteDatabase()`
- **Purpose**: Deletes the database file from the device. This is primarily useful for testing or resetting the application's local data.
- **Returns**: `Future<void>`
- **Functionality**:
  - Gets the database file path.
  - Uses `databaseFactory.deleteDatabase()` to delete the file.
  - Nullifies the `_database` instance.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
- `sqflite`
- `path` (for `path` package)
