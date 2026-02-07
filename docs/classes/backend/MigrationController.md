# Class: MigrationController

**Path:** `Backend/VTA.API/Controllers/MigrationController.cs`

## Overview
The `MigrationController` provides an API endpoint for triggering data migrations, specifically the reorganization of file storage from a flat structure to a user-based structure. This controller is designed for administrative or development purposes.

## Security Warning
The code comments explicitly state: "WARNING: This should be protected or removed in production". This indicates that exposing this endpoint in a production environment without strong authorization could pose a security risk, allowing unauthorized data migration or manipulation. Currently, it requires any authenticated user to trigger it, which might not be sufficient for production.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for interacting with data models during migration.

## Constructor

### `MigrationController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `MigrationController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used by the `MigrationService`.

## Methods

### `MigrateToUserBasedStorage([FromQuery] bool dryRun = true)`
- **Route**: `POST api/Migration/migrate-to-user-based-storage`
- **Authorization**: `[Authorize]`
- **Purpose**: Triggers the migration of stored files (artefact and category images/sounds) to a new user-based directory structure.
- **Parameters**:
  - `dryRun` (bool): A query parameter. If `true` (default), the migration will simulate the process without making any actual changes to the file system or database. If `false`, the migration will be executed live.
- **Returns**: `ActionResult<MigrationResult>`
  - `200 OK`: Returns a `MigrationResult` object indicating success and details of the migration (files moved, skipped, errors).
  - `500 Internal Server Error`: Returns a `MigrationResult` object indicating failure, or an anonymous object with an error message if an unexpected exception occurs.
- **Functionality**:
  - Creates an instance of `MigrationService`, passing the database context.
  - Calls `migration.MigrateAsync()` with the `dryRun` flag.
  - Returns the `MigrationResult` object, setting the HTTP status code to 500 if the migration was not successful.

## Internal Imports
- `VTA.API.Utilities`
- `VTA.Data.DbContexts`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
