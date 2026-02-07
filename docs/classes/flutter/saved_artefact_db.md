# Class: SavedArtefactDB

**Path:** `Frontend/vta_app/lib/src/database/models/saved_artefact_db.dart`

## Overview
The `SavedArtefactDB` class serves as a data model for representing a "saved artefact" record within the local SQLite database of the Flutter application. A saved artefact refers to an instance of an artefact that has been placed onto a board, complete with its specific position, size, and other display properties. It defines the structure of the `saved_artefact` table and provides utilities for converting between Dart objects and database-friendly `Map` objects.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `id` (String, required): The unique identifier for this specific instance of the saved artefact on a board.
- `artefactId` (String, required): The unique identifier of the base artefact that this saved artefact is an instance of.
- `boardId` (String, required): The unique identifier of the board on which this artefact is placed.
- `posX` (double): The X-coordinate for the artefact's position on the board. Defaults to `0`.
- `posY` (double): The Y-coordinate for the artefact's position on the board. Defaults to `0`.
- `width` (double): The width of the artefact on the board. Defaults to `200`.
- `height` (double): The height of the artefact on the board. Defaults to `200`.
- `createdDate` (int, required): A timestamp (Unix epoch milliseconds) indicating when this saved artefact was created/placed on the board.
- `modifiedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when this saved artefact's properties were last modified. Can be null.
- `nameVisible` (int?, nullable): A flag (0 or 1) indicating if the artefact's name should be visible for this specific instance on the board. Can be null.
- `isDeleted` (int): A flag (0 or 1) indicating if the saved artefact instance is marked for soft deletion. Defaults to `0`.

## Constructor

### `SavedArtefactDB({...})`
- **Purpose**: Initializes a new instance of the `SavedArtefactDB` class.
- **Parameters**:
  - `id` (required String)
  - `artefactId` (required String)
  - `boardId` (required String)
  - `posX` (double, optional, defaults to `0`)
  - `posY` (double, optional, defaults to `0`)
  - `width` (double, optional, defaults to `200`)
  - `height` (double, optional, defaults to `200`)
  - `createdDate` (required int)
  - `modifiedDate` (int?, optional)
  - `nameVisible` (int?, optional)
  - `isDeleted` (int, optional, defaults to 0)

## Methods

### `toMap()`
- **Purpose**: Converts the current `SavedArtefactDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations.
- **Returns**: `Map<String, dynamic>` - A map representation of the saved artefact's data.

### `factory SavedArtefactDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `SavedArtefactDB` instance from a `Map<String, dynamic>` retrieved from the database. It handles potential null values and type casting from `num` (which SQLite `INTEGER` columns might return) to `double`.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `SavedArtefactDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `SavedArtefactDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `SavedArtefactDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `SavedArtefactDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the saved artefact's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
