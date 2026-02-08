# Classes: MigrationService, MigrationResult

**Path:** `Backend/VTA.API/Utilities/MigrationService.cs`

## Overview
This file contains the `MigrationService` class, responsible for reorganizing stored files (images, sounds) from a flat structure to a user-based hierarchical structure. It also defines `MigrationResult` to report the outcome of a migration operation.

---

## Class: MigrationService

### Overview
The `MigrationService` facilitates the migration of existing artefact and category files to a new directory structure (`Assets/{type}/{userId}/{filename}`) from the old flat structure (`Assets/{type}/{filename}`). It interacts with the database to update file paths after moving.

### Extends
*(None)*

### Implements
*(None)*

### Properties
- `_context` (readonly `VTAContext`): The database context used to access and update artefact and category entities.
- `_assetsPath` (readonly string): The base path to the application's asset directory.
- `_movedFiles` (int): Counter for files successfully moved during migration.
- `_skippedFiles` (int): Counter for files skipped (e.g., already migrated, not found).
- `_errorFiles` (int): Counter for files that encountered an error during migration.

### Methods

#### `MigrationService(VTAContext context)` (Constructor)
- **Purpose**: Initializes a new instance of the `MigrationService`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, injected to allow access to data models.

#### `MigrateAsync(bool dryRun = false)`
- **Purpose**: Initiates the file migration process.
- **Parameters**:
  - `dryRun` (bool): If `true`, the migration will only simulate actions without actually moving files or updating the database. Defaults to `false`.
- **Returns**: A `MigrationResult` object summarizing the outcome of the migration.
- **Functionality**:
  - Prints migration mode and asset path to console.
  - Resets internal file counters.
  - Calls `MigrateArtefactsAsync` and `MigrateCategoriesAsync`.
  - Prints a summary of moved, skipped, and error files.
  - Handles fatal exceptions during the overall migration process.

#### `MigrateArtefactsAsync(bool dryRun)` (private)
- **Purpose**: Migrates image and sound files associated with `Artefact` entities.
- **Parameters**:
  - `dryRun` (bool): Passed to `MigrateFile`.
- **Functionality**:
  - Fetches all `Artefact` entities from the database.
  - Iterates through each artefact, calling `MigrateFile` for its `ImagePath` and `SoundPath`.
  - If not a dry run and files were moved, saves changes to the database.

#### `MigrateCategoriesAsync(bool dryRun)` (private)
- **Purpose**: Migrates image files associated with `Category` entities.
- **Parameters**:
  - `dryRun` (bool): Passed to `MigrateFile`.
- **Functionality**:
  - Fetches all `Category` entities from the database.
  - Iterates through each category, calling `MigrateFile` for its `ImagePath`.
  - If not a dry run and files were moved, saves changes to the database.

#### `MigrateFile(string apiPath, string type, string userId, string entityId, bool dryRun)` (private)
- **Purpose**: Handles the actual moving of a single file from its old location to the new user-specific location.
- **Parameters**:
  - `apiPath` (string): The API-relative path of the file (e.g., `/api/Assets/Artefacts/filename.png`).
  - `type` (string): The asset type directory (e.g., "Artefacts", "Categories", "Sounds").
  - `userId` (string): The ID of the user owning the file.
  - `entityId` (string): The ID of the entity (artefact/category) the file belongs to.
  - `dryRun` (bool): If `true`, simulates the move without executing it.
- **Returns**: The new API-relative path of the file if successfully moved/found, `null` otherwise.
- **Functionality**:
  - Constructs old and new file system paths.
  - Checks for file existence at old/new locations to handle already-migrated or missing files.
  - Creates the new user directory if it doesn't exist.
  - Performs the file move operation (or simulates it in dry run).
  - Updates internal counters (`_movedFiles`, `_skippedFiles`, `_errorFiles`).

---

## Class: MigrationResult

### Overview
`MigrationResult` is a simple data class used to encapsulate the results of a file migration operation, providing success status and counts of various outcomes.

### Properties
- `Success` (bool): Indicates whether the overall migration operation completed without fatal errors.
- `FilesMovedCount` (int): The total number of files that were successfully moved.
- `FilesSkippedCount` (int): The total number of files that were skipped (e.g., already migrated or not found at source).
- `ErrorsCount` (int): The total number of errors encountered during the migration.
- `ErrorMessage` (string, nullable): A message describing a fatal error if one occurred during the overall migration.

### Methods
*(None explicitly defined)*

---

## Internal Imports
- `VTA.Data.DbContexts`

## Notable Packages
- `Microsoft.EntityFrameworkCore`
