# Class: DatabaseDebugHelper

**Path:** `Frontend/vta_app/lib/src/database/database_debug_helper.dart`

## Overview
The `DatabaseDebugHelper` is a static helper class designed for debugging and development purposes within the Flutter application. It provides utility methods to inspect, manage, and reset the local SQLite database, offering functionalities like printing all table data, getting/printing database paths and statistics, and creating sample data.

## Extends
*(None, this is a static helper class)*

## Implements
*(None)*

## Properties
*(None explicitly defined)*

## Constructor
*(Uses an implicit default constructor, as all members are static.)*

## Methods

### `static Future<void> printAllData()`
- **Purpose**: Fetches and prints all records from all primary database tables (Users, Categories, Artefacts, Boards, Saved Artefacts, Sessions) to the console. Useful for quickly inspecting the entire database content during development.
- **Parameters**: None
- **Functionality**:
  - Prints a header "DATABASE CONTENTS".
  - Iterates through each repository (`UserRepository`, `CategoryRepository`, etc.) to `getAll()` records.
  - Prints the count and string representation of each record found.
  - Prints an error message if an exception occurs during database reading.

### `static Future<String> getDatabasePath()`
- **Purpose**: Asynchronously retrieves the absolute file system path to the SQLite database file (`vta.db`).
- **Parameters**: None
- **Returns**: `Future<String>` - The absolute path to the database file.

### `static Future<void> printDatabasePath()`
- **Purpose**: Prints the absolute file system path of the database to the console.
- **Parameters**: None
- **Functionality**:
  - Calls `getDatabasePath()`.
  - Prints the path or an error if retrieval fails.

### `static Future<Map<String, int>> getDatabaseStats()`
- **Purpose**: Retrieves a map of record counts for each main table in the database.
- **Parameters**: None
- **Returns**: `Future<Map<String, int>>` - A map where keys are table names (e.g., 'users', 'categories') and values are their respective record counts.

### `static Future<void> printDatabaseStats()`
- **Purpose**: Prints statistics (record counts per table) for the database to the console.
- **Parameters**: None
- **Functionality**:
  - Calls `getDatabaseStats()`.
  - Prints the counts for each table or an error if retrieval fails.

### `static Future<void> clearAllData()`
- **Purpose**: Deletes all data from all main tables in the database. **Use with caution** as this is a permanent operation.
- **Parameters**: None
- **Functionality**:
  - Calls `deleteAll()` on `UserRepository`, `CategoryRepository`, `ArtefactRepository`, `SavedBoardRepository`, `SavedArtefactRepository`, and `SessionMetaRepository`.
  - Prints success or error messages.

### `static Future<void> deleteDatabase()`
- **Purpose**: Deletes the entire database file from the device's file system. **Use with extreme caution** as this is permanent and will remove all local data.
- **Parameters**: None
- **Functionality**:
  - Calls `DatabaseHelper.instance.deleteDatabase()`.
  - Prints success or error messages.

### `static Future<void> createSampleData()`
- **Purpose**: Populates the database with sample user, category, and artefact data for testing and development.
- **Parameters**: None
- **Functionality**:
  - Creates instances of `UserDB`, `CategoryDB`, and `ArtefactDB` with predefined sample data.
  - Inserts these records into their respective repositories.
  - Prints success or error messages.
  - Calls `printDatabaseStats()` after creating sample data.

## Internal Imports
- `package:sqflite/sqflite.dart`
- `package:path/path.dart`
- `database.dart` (for `UserRepository`, `CategoryRepository`, `ArtefactRepository`, `SavedBoardRepository`, `SavedArtefactRepository`, `SessionMetaRepository`)

## Notable Packages
- `sqflite`
- `path`
