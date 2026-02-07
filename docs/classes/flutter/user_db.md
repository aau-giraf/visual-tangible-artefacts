# Class: UserDB

**Path:** `Frontend/vta_app/lib/src/database/models/user_db.dart`

## Overview
The `UserDB` class serves as a data model for representing a user record within the local SQLite database of the Flutter application. It defines the structure of the `user` table and provides utilities for converting between Dart objects and database-friendly `Map` objects. This model stores core user information, including preferences like `nameVisible` and `fieldCount`.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `id` (String, required): The unique identifier of the user.
- `name` (String?, nullable): The display name of the user. Can be null.
- `username` (String?, nullable): The username of the user. Can be null.
- `nameVisible` (int, required): A flag (0 or 1) indicating whether the user's name should be visible by default.
- `fieldCount` (int, required): The number of fields/columns to display, possibly related to layout settings.
- `modifiedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the user record was last modified. Can be null.
- `isDeleted` (int): A flag (0 or 1) indicating if the user record is marked for soft deletion. Defaults to `0`.

## Constructor

### `UserDB({...})`
- **Purpose**: Initializes a new instance of the `UserDB` class.
- **Parameters**:
  - `id` (required String)
  - `name` (String?, optional)
  - `username` (String?, optional)
  - `nameVisible` (required int)
  - `fieldCount` (required int)
  - `modifiedDate` (int?, optional)
  - `isDeleted` (int, optional, defaults to 0)

## Methods

### `toMap()`
- **Purpose**: Converts the current `UserDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations.
- **Returns**: `Map<String, dynamic>` - A map representation of the user's data.

### `factory UserDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `UserDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `UserDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `UserDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `UserDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `UserDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the user's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
