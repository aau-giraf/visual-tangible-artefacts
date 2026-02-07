# Class: ArtefactDB

**Path:** `Frontend/vta_app/lib/src/database/models/artefact_db.dart`

## Overview
The `ArtefactDB` class serves as a data model for representing an artefact record within the local SQLite database of the Flutter application. It defines the structure of the `artefact` table and provides utilities for converting between Dart objects and database-friendly `Map` objects.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `artefactId` (String, required): The unique identifier of the artefact.
- `artefactIndex` (int, required): The index of the artefact, possibly for ordering.
- `userId` (String, required): The unique identifier of the user who owns this artefact.
- `categoryId` (String?, nullable): The unique identifier of the category this artefact belongs to. Can be null.
- `imagePath` (String?, nullable): The local file path to the artefact's image. Can be null.
- `soundPath` (String?, nullable): The local file path to the artefact's sound. Can be null.
- `modifiedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the artefact was last modified. Can be null.
- `name` (String?, nullable): The name of the artefact. Can be null.
- `nameShown` (int, required): A flag (0 or 1) indicating whether the artefact's name should be displayed.
- `isDeleted` (int): A flag (0 or 1) indicating if the artefact is marked for soft deletion. Defaults to `0`.

## Constructor

### `ArtefactDB({...})`
- **Purpose**: Initializes a new instance of the `ArtefactDB` class.
- **Parameters**:
  - `artefactId` (required String)
  - `artefactIndex` (required int)
  - `userId` (required String)
  - `categoryId` (String?, optional)
  - `imagePath` (String?, optional)
  - `soundPath` (String?, optional)
  - `modifiedDate` (int?, optional)
  - `name` (String?, optional)
  - `nameShown` (required int)
  - `isDeleted` (int, optional, defaults to 0)

## Methods

### `toMap()`
- **Purpose**: Converts the current `ArtefactDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations.
- **Returns**: `Map<String, dynamic>` - A map representation of the artefact's data.

### `factory ArtefactDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates an `ArtefactDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `ArtefactDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `ArtefactDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `ArtefactDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `ArtefactDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the artefact's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
