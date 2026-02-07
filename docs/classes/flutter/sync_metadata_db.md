# Class: SyncMetadataDB

**Path:** `Frontend/vta_app/lib/src/database/models/sync_metadata_db.dart`

## Overview
The `SyncMetadataDB` class serves as a data model for representing synchronization metadata records within the local SQLite database of the Flutter application. It defines the structure of the `sync_metadata` table, which is used to track the last successful synchronization date for different types of entities (e.g., 'artefact', 'board') for a specific user. This helps in implementing efficient incremental synchronization.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `id` (int?, nullable): The primary key for the table. It's typically `AUTOINCREMENT` in the database, so it's nullable for inserts and automatically assigned.
- `userId` (String, required): The unique identifier of the user to whom this synchronization metadata belongs.
- `entityType` (String, required): A string indicating the type of entity this metadata applies to (e.g., 'artefact', 'board').
- `lastSyncDate` (int, required): A Unix timestamp (in seconds) representing the date and time of the last successful synchronization for this entity type and user.
- `lastCheckDate` (int, required): A Unix timestamp (in seconds) representing the date and time when the last check for changes was performed.

## Constructor

### `SyncMetadataDB({...})`
- **Purpose**: Initializes a new instance of the `SyncMetadataDB` class.
- **Parameters**:
  - `id` (int?, optional)
  - `userId` (required String)
  - `entityType` (required String)
  - `lastSyncDate` (required int)
  - `lastCheckDate` (required int)

## Methods

### `toMap()`
- **Purpose**: Converts the current `SyncMetadataDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations. The `id` field is only included in the map if it's not null (e.g., for updates, not new inserts where the DB assigns the ID).
- **Returns**: `Map<String, dynamic>` - A map representation of the synchronization metadata.

### `factory SyncMetadataDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `SyncMetadataDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `SyncMetadataDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `SyncMetadataDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `SyncMetadataDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `SyncMetadataDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the synchronization metadata's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
