# Class: SavedBoardDB

**Path:** `Frontend/vta_app/lib/src/database/models/saved_board_db.dart`

## Overview
The `SavedBoardDB` class serves as a data model for representing a saved board record within the local SQLite database of the Flutter application. It defines the structure of the `saved_board` table and provides utilities for converting between Dart objects and database-friendly `Map` objects. Notably, it stores lists of `savedArtefactIds` and `artefactIds` as JSON strings.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `id` (String, required): The unique identifier of the saved board.
- `name` (String, required): The name of the board.
- `userId` (String, required): The unique identifier of the user who owns this board.
- `savedArtefactIds` (String?, nullable): A JSON string representing a list of unique identifiers for saved artefact instances associated with this board. Can be null.
- `artefactIds` (String?, nullable): A JSON string representing a list of unique identifiers for the base artefacts associated with this board. Can be null.
- `snapshotPath` (String?, nullable): The local file path to a snapshot/thumbnail image of the board. Can be null.
- `createdDate` (int, required): A timestamp (Unix epoch milliseconds) indicating when the board was created.
- `modifiedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the board was last modified. Can be null.
- `isDeleted` (int): A flag (0 or 1) indicating if the board is marked for soft deletion. Defaults to `0`.

## Constructor

### `SavedBoardDB({...})`
- **Purpose**: Initializes a new instance of the `SavedBoardDB` class.
- **Parameters**:
  - `id` (required String)
  - `name` (required String)
  - `userId` (required String)
  - `savedArtefactIds` (String?, optional)
  - `artefactIds` (String?, optional)
  - `snapshotPath` (String?, optional)
  - `createdDate` (required int)
  - `modifiedDate` (int?, optional)
  - `isDeleted` (int, optional, defaults to 0)

## Methods

### `toMap()`
- **Purpose**: Converts the current `SavedBoardDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations.
- **Returns**: `Map<String, dynamic>` - A map representation of the board's data.

### `factory SavedBoardDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `SavedBoardDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `SavedBoardDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `SavedBoardDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `SavedBoardDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `SavedBoardDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the board's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
