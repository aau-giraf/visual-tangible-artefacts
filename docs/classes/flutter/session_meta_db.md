# Class: SessionMetaDB

**Path:** `Frontend/vta_app/lib/src/database/models/session_meta_db.dart`

## Overview
The `SessionMetaDB` class serves as a data model for representing session metadata records within the local SQLite database of the Flutter application. It defines the structure of the `session_meta` table, storing information such as the session's ID, associated board and user IDs, start time, last sync time, and a dirty flag for synchronization purposes. It also provides utilities for converting between Dart objects and database-friendly `Map` objects.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `id` (int?, nullable): The primary key for the table. It's `AUTOINCREMENT` in the database, so it's nullable for inserts and automatically assigned.
- `sessionId` (String?, nullable): The unique identifier of the session. Can be null.
- `boardId` (String, required): The unique identifier of the board associated with this session.
- `userId` (String, required): The unique identifier of the user participating in this session.
- `startedAt` (int, required): A timestamp (Unix epoch milliseconds) indicating when the session started.
- `lastSyncedAt` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the session metadata was last synchronized with the backend. Can be null.
- `isDirty` (int, required): A flag (0 or 1) indicating if the session metadata has local changes that need to be synchronized with the backend.

## Constructor

### `SessionMetaDB({...})`
- **Purpose**: Initializes a new instance of the `SessionMetaDB` class.
- **Parameters**:
  - `id` (int?, optional)
  - `sessionId` (String?, optional)
  - `boardId` (required String)
  - `userId` (required String)
  - `startedAt` (required int)
  - `lastSyncedAt` (int?, optional)
  - `isDirty` (required int)

## Methods

### `toMap()`
- **Purpose**: Converts the current `SessionMetaDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations. The `id` field is only included in the map if it's not null (e.g., for updates, not new inserts where the DB assigns the ID).
- **Returns**: `Map<String, dynamic>` - A map representation of the session metadata.

### `factory SessionMetaDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `SessionMetaDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `SessionMetaDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `SessionMetaDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `SessionMetaDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `SessionMetaDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the session metadata's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
