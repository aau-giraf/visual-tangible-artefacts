# Class: CategoryDB

**Path:** `Frontend/vta_app/lib/src/database/models/category_db.dart`

## Overview
The `CategoryDB` class serves as a data model for representing a category record within the local SQLite database of the Flutter application. It defines the structure of the `category` table and provides utilities for converting between Dart objects and database-friendly `Map` objects.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `categoryId` (String, required): The unique identifier of the category.
- `categoryIndex` (int?, nullable): The index of the category, possibly for ordering. Can be null.
- `userId` (String, required): The unique identifier of the user who owns this category.
- `name` (String?, nullable): The name of the category. Can be null.
- `imagePath` (String?, nullable): The local file path to the category's image. Can be null.
- `modifiedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the category was last modified. Can be null.
- `usageCount` (int): A counter for how many times this category has been used. Defaults to `0`.
- `lastUsedDate` (int?, nullable): A timestamp (Unix epoch milliseconds) indicating when the category was last accessed or used. Can be null.
- `isDeleted` (int): A flag (0 or 1) indicating if the category is marked for soft deletion. Defaults to `0`.

## Constructor

### `CategoryDB({...})`
- **Purpose**: Initializes a new instance of the `CategoryDB` class.
- **Parameters**:
  - `categoryId` (required String)
  - `categoryIndex` (int?, optional)
  - `userId` (required String)
  - `name` (String?, optional)
  - `imagePath` (String?, optional)
  - `modifiedDate` (int?, optional)
  - `usageCount` (int, optional, defaults to 0)
  - `lastUsedDate` (int?, optional)
  - `isDeleted` (int, optional, defaults to 0)

## Methods

### `toMap()`
- **Purpose**: Converts the current `CategoryDB` object into a `Map<String, dynamic>` suitable for database insertion or update operations.
- **Returns**: `Map<String, dynamic>` - A map representation of the category's data.

### `factory CategoryDB.fromMap(Map<String, dynamic> map)`
- **Purpose**: A factory constructor that creates a `CategoryDB` instance from a `Map<String, dynamic>` retrieved from the database.
- **Parameters**:
  - `map` (`Map<String, dynamic>`): The map containing database column data.
- **Returns**: `CategoryDB` - A new instance populated with data from the map.

### `copyWith({...})`
- **Purpose**: Creates a new `CategoryDB` instance, optionally replacing specified fields with new values while retaining existing values for unspecified fields. This is useful for immutable data patterns.
- **Parameters**: All properties are optional named parameters, allowing partial updates.
- **Returns**: `CategoryDB` - A new instance with updated properties.

### `toString()`
- **Purpose**: Provides a string representation of the `CategoryDB` object, primarily for debugging purposes.
- **Returns**: `String` - A JSON-like string showing the category's properties.

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard Dart libraries)*
