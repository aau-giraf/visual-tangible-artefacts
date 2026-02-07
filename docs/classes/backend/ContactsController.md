# Class: ContactsController

**Path:** `Backend/VTA.API/Controllers/ContactsController.cs`

## Overview
The `ContactsController` is an API controller responsible for retrieving contact information (caregivers for children, children for caregivers) related to the currently authenticated user. All endpoints in this controller are protected by JWT authentication.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
*(None explicitly defined beyond injected dependencies)*

## Constructor

### `ContactsController(VTAContext context, IConfiguration config, ILogger<ContactsController> logger)`
- **Purpose**: Initializes a new instance of the `ContactsController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with user and relation data.
  - `config` (`IConfiguration`): The application's configuration (appears to be injected but not directly used in the provided snippet).
  - `logger` (`ILogger<ContactsController>`): A logger instance for logging internal events and information.

## Methods

### `GetContacts()`
- **Route**: `GET api/Contacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a list of related users (contacts) for the current authenticated user. Specifically, it returns connected children if the current user is a caregiver, or connected caregivers if the current user is a child.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects representing the related contacts.
  - `401 Unauthorized`: If the user ID cannot be found in the authentication token.
  - `404 Not Found`: If the current authenticated user is not found in the database.
- **Functionality**:
  - Logs an informational message about fetching contacts.
  - Extracts the `userId` from the JWT.
  - Retrieves the `currentUser` from the database.
  - **If `currentUser.Role` is `Caregiver`**:
    - Queries `Relations` to find all active connections where the `CaregiverId` matches the `userId`.
    - Eagerly includes the `Child` user entity for each relation.
    - Maps the `Child` entities to `UserGetDTO`s.
  - **If `currentUser.Role` is `Child`**:
    - Queries `Relations` to find all active connections where the `ChildId` matches the `userId`.
    - Eagerly includes the `Caregiver` user entity for each relation.
    - Maps the `Caregiver` entities to `UserGetDTO`s.
  - Returns the list of `UserGetDTO`s.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.Extensions.Configuration` (injected but unused in snippet)
- `Microsoft.Extensions.Logging`
