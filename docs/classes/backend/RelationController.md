# Class: RelationController

**Path:** `Backend/VTA.API/Controllers/RelationController.cs`

## Overview
The `RelationController` is an API controller dedicated to managing caregiver-child pairings (relations). All endpoints in this controller are protected and require the authenticated user to have the "Admin" role, reflecting its administrative nature for managing these connections.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `_context` (private readonly `VTAContext`): The database context for accessing relation and user data.

## Constructor

### `RelationController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `RelationController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with relation and user data.

## Methods

### `GetPairings()`
- **Route**: `GET api/Relation`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of all caregiver-child pairings (both active and inactive).
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<PairingDTO>>`
  - `200 OK`: Returns a list of `PairingDTO` objects, including details about the caregiver and child.
- **Functionality**:
  - Queries the database for all `Relation` entities.
  - Eagerly loads `Caregiver` and `Child` user entities.
  - Maps `Relation` entities to `PairingDTO`s using a custom select.

### `GetPairingsForCaregiver(string caregiverId)`
- **Route**: `GET api/Relation/caregiver/{caregiverId}`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Retrieves a list of active pairings for a specific caregiver.
- **Parameters**:
  - `caregiverId` (string): The ID of the caregiver whose pairings are to be retrieved.
- **Returns**: `ActionResult<IEnumerable<PairingDTO>>`
  - `200 OK`: Returns a list of `PairingDTO` objects.
- **Functionality**:
  - Queries the database for `Relation` entities where `CaregiverId` matches and `IsActive` is true.
  - Eagerly loads `Caregiver` and `Child` user entities.
  - Maps `Relation` entities to `PairingDTO`s.

### `CreatePairing(CreatePairingDTO createDto)`
- **Route**: `POST api/Relation`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Creates a new caregiver-child pairing.
- **Parameters**:
  - `createDto` (`CreatePairingDTO`): An object containing the `CaregiverId` and `ChildId`.
- **Returns**: `ActionResult<PairingDTO>`
  - `201 CreatedAtAction`: Returns the created `PairingDTO` upon successful creation.
  - `400 Bad Request`: If either the caregiver or child is invalid (e.g., wrong role or not found).
  - `409 Conflict`: If an active pairing between the specified caregiver and child already exists.
- **Functionality**:
  - Finds the caregiver and child users by their IDs and validates their roles.
  - Checks for an existing active pairing between the two users.
  - Creates a new `Relation` entity, setting `IsActive` to `true` by default.
  - Adds the new relation to the database and saves changes.
  - Maps the created `Relation` to a `PairingDTO` for the response.

### `RemovePairing(string id)`
- **Route**: `DELETE api/Relation/{id}`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Deactivates a specific caregiver-child pairing by its ID (soft delete).
- **Parameters**:
  - `id` (string): The ID of the pairing (relation) to deactivate.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deactivation.
  - `404 Not Found`: If the pairing with the specified ID is not found.
- **Functionality**:
  - Finds the `Relation` entity by ID.
  - Sets its `IsActive` property to `false`.
  - Saves changes to the database.

### `RemovePairingByIds([FromBody] CreatePairingDTO removeDto)`
- **Route**: `DELETE api/Relation`
- **Authorization**: `[Authorize(Roles = "Admin")]`
- **Purpose**: Deactivates a specific caregiver-child pairing by providing both caregiver and child IDs (soft delete).
- **Parameters**:
  - `removeDto` (`CreatePairingDTO`): An object containing the `CaregiverId` and `ChildId` of the pairing to remove.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deactivation.
  - `404 Not Found`: If an active pairing between the specified caregiver and child is not found.
- **Functionality**:
  - Finds the active `Relation` entity by `CaregiverId` and `ChildId`.
  - Sets its `IsActive` property to `false`.
  - Saves changes to the database.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
