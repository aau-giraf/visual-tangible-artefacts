# Class: CategoriesController

**Path:** `Backend/VTA.API/Controllers/CategoriesController.cs`

## Overview
The `CategoriesController` is an API controller dedicated to managing categories owned by a user. It provides endpoints for creating, retrieving, updating, and deleting categories, as well as tracking category usage. All endpoints are protected by JWT authentication at the class level.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
*(None explicitly defined)*

## Constructor

### `CategoriesController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `CategoriesController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with category and related data.

## Methods

### `GetCategories()`
- **Route**: `GET api/Categories`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves all categories (and the artefacts within them) that belong to the currently authenticated user.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<CategoryGetDTO>>`
  - `200 OK`: Returns a list of `CategoryGetDTO` objects.
  - `404 Not Found`: If no categories are found for the user.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Queries the database for categories belonging to the `userId`, including their `Artefacts`.
  - Maps `Category` entities to `CategoryGetDTO`s using `DTOConverter`.

### `GetCategory(string categoryId)`
- **Route**: `GET api/Categories/{categoryId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a specific category and its associated artefacts, owned by the authenticated user.
- **Parameters**:
  - `categoryId` (string): The unique identifier of the category to retrieve.
- **Returns**: `ActionResult<CategoryGetDTO>`
  - `200 OK`: Returns the `CategoryGetDTO` for the specified category.
  - `404 Not Found`: If the category is not found or is not owned by the user.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Queries the database for the category by `categoryId` and `userId`, including its `Artefacts`.
  - Maps the `Category` entity to a `CategoryGetDTO`.

### `PatchCategory([FromForm] CategoryPatchDTO dto)`
- **Route**: `PATCH api/Categories`
- **Authorization**: `[Authorize]`
- **Purpose**: Partially updates an existing category's information, including its index, name, and image.
- **Parameters**:
  - `dto` (`CategoryPatchDTO`): An object containing the fields to be updated, submitted as form data.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `400 Bad Request`: If the category specified in the DTO is not found.
  - `404 Not Found`: If the category does not exist (during concurrency handling).
- **Functionality**:
  - Extracts the `userId` from the JWT (used for `ImageUtilities`).
  - Retrieves the category by `CategoryId` from the DTO.
  - Updates `CategoryIndex` and `Name` if provided in the DTO.
  - Handles image updates: deletes the old image using `ImageUtilities.DeleteImage` and adds the new image using `ImageUtilities.AddImage`.
  - Marks the category entity as `Modified` and saves changes to the database, handling `DbUpdateConcurrencyException`.

### `PostCategory([FromForm] CategoryPostDTO categoryPostDTO)`
- **Route**: `POST api/Categories`
- **Authorization**: `[Authorize]`
- **Purpose**: Creates a new category or updates an existing one if `CategoryId` is provided. Handles image file uploads.
- **Parameters**:
  - `categoryPostDTO` (`CategoryPostDTO`): An object with all category information, submitted as form data.
- **Returns**: `ActionResult<CategoryGetDTO>`
  - `200 OK`: Returns the created or updated `CategoryGetDTO`.
  - `403 Forbidden`: If the authenticated user's ID does not match the `UserId` in the DTO.
  - `404 Not Found`: If the category is not found after creation (should not happen normally).
  - `409 Conflict`: If an ID collision occurs during creation.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Verifies that the `userId` matches the `CategoryPostDTO.UserId`.
  - Checks if `categoryPostDTO.CategoryId` is provided; if so, attempts to update an existing category.
  - For new categories, generates a new `Guid` for `CategoryId`.
  - Handles image file uploads using `ImageUtilities.AddImage`, deleting old images if present during updates.
  - Adds the new category to the context or updates the existing one.
  - Saves changes to the database, handling `DbUpdateException` for ID conflicts.
  - Maps the resulting `Category` to `CategoryGetDTO`.

### `DeleteCategory(string categoryId)`
- **Route**: `DELETE api/Categories/{categoryId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Deletes a specific category and all its associated artefacts (due to cascade delete) and their corresponding image files from the file system.
- **Parameters**:
  - `categoryId` (string): The unique identifier of the category to delete.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deletion.
  - `403 Forbidden`: If the authenticated user does not own the category.
  - `404 Not Found`: If the category does not exist.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Finds the category by `categoryId`.
  - Verifies user ownership of the category.
  - Iterates through the category's artefacts to delete their associated image files using `ImageUtilities.DeleteImage`.
  - Deletes the category's image file.
  - Removes the category from the context and saves changes (relying on MySQL cascade delete for artefacts).

### `TrackCategoryUsage(string categoryId)`
- **Route**: `POST api/Categories/{categoryId}/usage`
- **Authorization**: `[Authorize]`
- **Purpose**: Increments the `UsageCount` and updates `LastUsedDate` for a specified category.
- **Parameters**:
  - `categoryId` (string): The ID of the category to track usage for.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `403 Forbidden`: If the user does not own the category.
  - `404 Not Found`: If the category does not exist.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Finds the category by `categoryId`.
  - Verifies user ownership.
  - Increments `UsageCount` and sets `LastUsedDate` to `DateTime.UtcNow`.
  - Marks the category entity as `Modified` and saves changes, handling `DbUpdateConcurrencyException`.

### `GetMostUsedCategories(int limit = 5)`
- **Route**: `GET api/Categories/most-used`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a list of the most used categories for the authenticated user, ordered by usage count and then last used date.
- **Parameters**:
  - `limit` (int): The maximum number of categories to return (defaults to 5).
- **Returns**: `ActionResult<IEnumerable<CategoryGetDTO>>`
  - `200 OK`: Returns a list of `CategoryGetDTO` objects.
  - `404 Not Found`: If no categories are found for the user.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Queries the database for categories belonging to the `userId`, including their `Artefacts`.
  - Orders the results by `UsageCount` (descending) and then `LastUsedDate` (descending).
  - Takes the specified `limit` number of categories.
  - Maps `Category` entities to `CategoryGetDTO`s.

### `CategoryExists(string id)` (private)
- **Purpose**: Checks if a category with the given ID exists in the database.
- **Parameters**:
  - `id` (string): The category ID to check.
- **Returns**: `bool` - `true` if a category with the ID exists, `false` otherwise.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.API.Utilities`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.IdentityModel.Tokens` (appears in `using` but is not directly used in the provided snippet)
