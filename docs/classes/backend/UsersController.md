# Class: UsersController

**Path:** `Backend/VTA.API/Controllers/UsersController.cs`

## Overview
The `UsersController` is an API controller responsible for handling all user-related operations, including authentication (login, signup), user management (retrieval, update, deletion), and managing user-specific settings and related contacts. The controller is marked with `[Authorize]` at the class level, meaning most endpoints require a valid JWT for access, with exceptions explicitly marked `[AllowAnonymous]`.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
*(None explicitly defined beyond injected dependencies)*

## Constructor

### `UsersController(VTAContext context, IConfiguration config)`
- **Purpose**: Initializes a new instance of the `UsersController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with user and related data.
  - `config` (`IConfiguration`): The application's configuration, used primarily for retrieving the JWT secret.

## Methods

### `Login(UserLoginDTO userLoginForm)`
- **Route**: `POST api/Users/Login`
- **Authorization**: `[AllowAnonymous]`
- **Purpose**: Authenticates a user based on provided username and password.
- **Parameters**:
  - `userLoginForm` (`UserLoginDTO`): An object containing the user's username and password.
- **Returns**: `ActionResult<UserLoginResponseDTO>`
  - `200 OK`: Returns a `UserLoginResponseDTO` containing a JWT and the user's ID upon successful authentication.
  - `400 Bad Request`: If `userLoginForm` is null.
  - `404 Not Found`: If the user is not found or the password is incorrect (intentionally generic for security).
- **Functionality**:
  - Retrieves user by username from the database.
  - Verifies the provided password against the stored hashed password using `BCrypt.Net.BCrypt.Verify`.
  - Generates a JWT token using `GenerateJwt` method.

### `SingUp(UserSignupDTO userSignUp)`
- **Route**: `POST api/Users/SignUp`
- **Authorization**: `[AllowAnonymous]`
- **Purpose**: Registers a new user account in the system.
- **Parameters**:
  - `userSignUp` (`UserSignupDTO`): An object containing the new user's username, password, name, and role.
- **Returns**: `ActionResult<UserLoginResponseDTO>`
  - `200 OK`: Returns a `UserLoginResponseDTO` by automatically signing in the newly created user.
  - `400 Bad Request`: If `userSignUp` is null.
  - `409 Conflict`: If the username already exists or a user ID conflict occurs during database save.
- **Functionality**:
  - Checks if the provided username already exists.
  - Maps the `UserSignupDTO` to a `User` model, generating a new GUID for the user ID.
  - Hashes the user's password using `BCrypt.Net.BCrypt.HashPassword`.
  - Creates a default `SavedBoard` for the new user.
  - Saves changes to the database.
  - Automatically signs in the new user using `AutoSignIn`.
- **Remarks**: The method name `SingUp` contains a typo and should ideally be `SignUp`.

### `AutoSignIn(User user)` (private)
- **Purpose**: Automatically signs in a newly created user by generating a JWT.
- **Parameters**:
  - `user` (`User`): The user object that was just created.
- **Returns**: `ActionResult<UserLoginResponseDTO>` containing the JWT and user ID.
- **Functionality**:
  - Maps the `User` to a `UserGetDTO`.
  - Generates a JWT token for the user.

### `GetUsers()`
- **Route**: `GET api/Users`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a list of all users in the database.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects.
- **Functionality**:
  - Fetches all `User` entities from the database without tracking changes.
  - Maps each `User` to a `UserGetDTO`.
- **Remarks**: The comment notes this endpoint was possibly intended to be removed or altered to retrieve only users related to a parent/pedagogue/teacher.

### `GetRelatedContacts()`
- **Route**: `GET api/Users/related-contacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves contacts (children for caregivers, caregivers for children) related to the current authenticated user.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<UserGetDTO>>`
  - `200 OK`: Returns a list of `UserGetDTO` objects representing related contacts.
  - `401 Unauthorized`: If the user ID is not found in the token.
  - `404 Not Found`: If the current user is not found.
- **Functionality**:
  - Extracts the current user's ID from the JWT.
  - Retrieves the current user from the database.
  - If the current user is a `Caregiver`, it fetches all active `Relation` entries where they are the caregiver and includes the `Child` user.
  - If the current user is a `Child`, it fetches all active `Relation` entries where they are the child and includes the `Caregiver` user.
  - Maps the related `User` entities to `UserGetDTO`s.

### `GetUser(string id)`
- **Route**: `GET api/Users/{id}`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves detailed information about a specific user by their ID.
- **Parameters**:
  - `id` (string): The ID of the user to retrieve.
- **Returns**: `ActionResult<UserGetDTO>`
  - `200 OK`: Returns a `UserGetDTO` for the specified user.
  - `404 Not Found`: If the user with the given ID does not exist.
- **Functionality**:
  - Retrieves the user by ID from the database without tracking changes.
  - Maps the `User` to a `UserGetDTO`.
- **Remarks**: The comment suggests that current logic allows fetching any user, but might be intended for restriction to the logged-in user or related contacts.

### `PutUser(string id, User user)`
- **Route**: `PUT api/Users/{id}`
- **Authorization**: `[Authorize]`
- **Purpose**: Updates an existing user's information.
- **Parameters**:
  - `id` (string): The ID of the user to update (from the route).
  - `user` (`User`): The complete user object with updated information.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `400 Bad Request`: If the route `id` does not match the `user.Id` in the body.
  - `404 Not Found`: If the user to be updated does not exist.
- **Functionality**:
  - Checks if the route ID matches the user object's ID.
  - Marks the `user` entity's state as `Modified` in the context.
  - Saves changes to the database, handling potential `DbUpdateConcurrencyException`.
- **Remarks**: The comment highlights the expectation of DTOs for parameters and returns to prevent over-exposure and circular dependencies, noting this method has not been updated to use DTOs.

### `DeleteUser(string id)`
- **Route**: `DELETE api/Users/{id}`
- **Authorization**: `[Authorize]`
- **Purpose**: Deletes a user and all their associated data, including artefacts, categories, saved boards, and their corresponding files from the file system.
- **Parameters**:
  - `id` (string): The ID of the user to delete.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deletion.
  - `403 Forbidden`: If the authenticated user's ID does not match the `id` in the route (preventing deletion of other users).
  - `404 Not Found`: If the user does not exist.
- **Functionality**:
  - Extracts the authenticated user's ID from the JWT.
  - Verifies that the authenticated user is trying to delete their own account.
  - Eagerly loads the `User` with their `Categories`, `Artefacts`, and `SavedBoards` (and nested `SavedArtefacts`).
  - Iterates through the user's categories and artefacts to delete corresponding image and sound files using `ImageUtilities.DeleteImage` and `SoundUtilities.DeleteSound`.
  - Iterates through the user's saved boards to delete snapshot files and associated `SavedArtefact` entries.
  - Removes the `User` entity from the context, relying on cascade delete configurations in the database for related entities.
  - Saves changes to the database.

### `PatchUser([FromBody] UserPatchDTO dto)`
- **Route**: `PATCH api/Users`
- **Authorization**: `[Authorize]`
- **Purpose**: Partially updates user settings such as `NameVisible` and `FieldCount`.
- **Parameters**:
  - `dto` (`UserPatchDTO`): An object containing the fields to be updated.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `401 Unauthorized`: If the user ID cannot be extracted from the token.
  - `404 Not Found`: If the user is not found.
- **Functionality**:
  - Extracts the current user's ID from the JWT.
  - Finds the user in the database.
  - Updates `user.NameVisible` and `user.FieldCount` if the corresponding fields are provided in the `dto`.
  - Marks the `user` entity's state as `Modified` and saves changes.

### `UserIdExists(string id)` (private)
- **Purpose**: Checks if a user with the given ID exists in the database.
- **Parameters**:
  - `id` (string): The user ID to check.
- **Returns**: `true` if a user with the ID exists, `false` otherwise.

### `UsernameExists(string username)` (private)
- **Purpose**: Checks if a user with the given username exists in the database.
- **Parameters**:
  - `username` (string): The username to check.
- **Returns**: `true` if a user with the username exists, `false` otherwise.

### `GenerateJwt(User user)` (private)
- **Purpose**: Generates a JSON Web Token (JWT) for a given user, used for authorization.
- **Parameters**:
  - `user` (`User`): The user object for whom the token is being generated.
- **Returns**: `string` - A valid JWT.
- **Throws**: `InvalidOperationException` if the JWT secret is not configured.
- **Functionality**:
  - Retrieves the JWT secret from application configuration or environment variables.
  - Defines the issuer and audience for the token.
  - Creates `SymmetricSecurityKey` and `SigningCredentials` using the secret.
  - Constructs claims for the token, including user ID, role, and a unique JTI.
  - Creates a `JwtSecurityToken` with specified expiration and signing credentials.
  - Serializes the token to a string.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.API.Utilities`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.IdentityModel.Tokens`
- `System.IdentityModel.Tokens.Jwt`
- `System.Security.Claims`
- `System.Text`
- `BCrypt.Net` (implicitly used for password hashing)
