# Class: AdminController

**Path:** `Backend/VTA.API/Controllers/AdminController.cs`

## Overview
The `AdminController` provides administrative functionalities for managing users and their pairings within the system. All endpoints in this controller are protected and require the authenticated user to have the "Admin" role.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for accessing user and relation data.

## Constructor

### `AdminController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `AdminController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with user and relation data.

## Methods

### `GetCaregivers()`
- **Route**: `GET api/Admin/caregivers`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of all users with the `Caregiver` role.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects for all caregivers.
- **Functionality**:
  - Queries the database for users where `Role` is `UserRole.Caregiver`.
  - Maps these `User` entities to `UserGetDTO`s using `DTOConverter`.

### `GetChildren()`
- **Route**: `GET api/Admin/children`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of all users with the `Child` role.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects for all children.
- **Functionality**:
  - Queries the database for users where `Role` is `UserRole.Child`.
  - Maps these `User` entities to `UserGetDTO`s using `DTOConverter`.

### `GetAdmins()`
- **Route**: `GET api/Admin/admins`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of all users with the `Admin` role.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects for all admins.
- **Functionality**:
  - Queries the database for users where `Role` is `UserRole.Admin`.
  - Maps these `User` entities to `UserGetDTO`s using `DTOConverter`.

### `CreateAdmin(UserSignupDTO adminDto)`
- **Route**: `POST api/Admin/admins`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Creates a new user account with the `Admin` role.
- **Parameters**:
  - `adminDto` (`UserSignupDTO`): Contains the username, name, and password for the new admin.
- **Returns**: `ActionResult<UserGetDTO>`
  - `201 CreatedAtAction`: Returns the created `UserGetDTO`.
  - `409 Conflict`: If a user with the provided username already exists.
- **Functionality**:
  - Checks if the username already exists.
  - Creates a new `User` entity, setting its `Role` to `UserRole.Admin`.
  - Hashes the password using `BCrypt.Net.BCrypt.HashPassword`.
  - Adds the new admin to the database and saves changes.

### `DeleteUser(string id)`
- **Route**: `DELETE api/Admin/users/{id}`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Deletes a user account by their ID.
- **Parameters**:
  - `id` (string): The ID of the user to delete.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deletion.
  - `404 Not Found`: If the user with the specified ID is not found.
- **Functionality**:
  - Finds the user by ID.
  - Removes the user from the database and saves changes.

### `MakeUserAdmin(string id)`
- **Route**: `POST api/Admin/users/{id}/make-admin`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Changes an existing user's role to `Admin`.
- **Parameters**:
  - `id` (string): The ID of the user to promote to admin.
- **Returns**: `IActionResult`
  - `200 OK`: On successful role update.
  - `404 Not Found`: If the user with the specified ID is not found.
- **Functionality**:
  - Finds the user by ID.
  - Sets the user's `Role` to `UserRole.Admin`.
  - Saves changes to the database.

### `GetPairings()`
- **Route**: `GET api/Admin/pairings`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of all active caregiver-child pairings.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<object>>` (returning an anonymous type)
  - `200 OK`: Returns a list of objects, each representing an active pairing with detailed caregiver and child information.
- **Functionality**:
  - Queries `Relations` where `IsActive` is true.
  - Eagerly loads `Caregiver` and `Child` user details.
  - Selects an anonymous object containing pairing ID, caregiver/child IDs, and nested objects for caregiver/child details.

### `CreatePairing([FromBody] CreatePairingRequest request)`
- **Route**: `POST api/Admin/pairings`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Creates a new caregiver-child pairing.
- **Parameters**:
  - `request` (`CreatePairingRequest`): Contains `CaregiverId` and `ChildId`.
- **Returns**: `ActionResult`
  - `200 OK`: On successful pairing creation, returns a message and the new pairing ID.
  - `404 Not Found`: If either caregiver or child user is not found.
  - `400 Bad Request`: If the specified caregiver is not a `Caregiver` role or the child is not a `Child` role.
  - `409 Conflict`: If the pairing already exists.
- **Functionality**:
  - Finds the caregiver and child users by their IDs.
  - Validates that the caregiver has the `Caregiver` role and the child has the `Child` role.
  - Checks if an active pairing between them already exists.
  - Creates a new `Relation` entry, sets `IsActive` to `true`, and records `CreatedAt`.
  - Adds the pairing to the database and saves changes.

### `DeletePairing(string id)`
- **Route**: `DELETE api/Admin/pairings/{id}`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Deactivates a caregiver-child pairing (soft delete).
- **Parameters**:
  - `id` (string): The ID of the pairing (relation) to deactivate.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deactivation.
  - `404 Not Found`: If the pairing is not found.
- **Functionality**:
  - Finds the `Relation` by ID.
  - Sets `IsActive` to `false`.
  - Saves changes to the database.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `BCrypt.Net` (implicitly used for password hashing in `CreateAdmin`)
