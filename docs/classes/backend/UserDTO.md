# Classes: UserPostDTO, UserGetDTO, UserSignupDTO, UserLoginDTO, UserLoginResponseDTO, UserPatchDTO

**Path:** `Backend/VTA.API/DTOs/UserDTO.cs`

## Overview
This file defines a collection of Data Transfer Objects (DTOs) specifically crafted for managing user-related operations within the API. These DTOs facilitate user creation, retrieval, login, signup, and partial updates to user settings.

---

## Class: UserPostDTO

### Overview
`UserPostDTO` is used for creating new user accounts, typically by an administrator or through a dedicated registration process.

### Properties
- `Name` (string, required, nullable): The display name of the user.
- `Password` (string, required): The user's password.
- `Username` (string): The unique username for the user.
- `Role` (`UserRole`): The role assigned to the user. Defaults to `UserRole.Child`.

### Methods
*(None explicitly defined)*

---

## Class: UserGetDTO

### Overview
`UserGetDTO` is used for retrieving and exposing user data from the API, including their basic information, settings, and associated categories.

### Properties
- `Id` (string): The unique identifier of the user.
- `Name` (string, nullable): The display name of the user.
- `Username` (string): The unique username.
- `NameVisible` (bool): Indicates if the user's name should be visible.
- `FieldCount` (int): A setting for the number of fields in a linear layout for this user.
- `Role` (`UserRole`): The role of the user.
- `Categories` (`ICollection<CategoryGetDTO>`): A collection of categories associated with the user.

### Methods
*(None explicitly defined)*

---

## Class: UserSignupDTO

### Overview
`UserSignupDTO` is used for user registration requests, capturing essential information required to create a new user account.

### Properties
- `Username` (string, required): The unique username for the new account.
- `Password` (string, required): The password for the new account.
- `Name` (string, required): The display name of the new user.
- `Role` (`UserRole`): The role to assign to the new user. Defaults to `UserRole.Child`.

### Methods
*(None explicitly defined)*

---

## Class: UserLoginDTO

### Overview
`UserLoginDTO` is used for user authentication requests, containing the credentials required for login.

### Properties
- `Username` (string, required): The username for login.
- `Password` (string, required): The password for login.

### Methods
*(None explicitly defined)*

---

## Class: UserLoginResponseDTO

### Overview
`UserLoginResponseDTO` is used to return the authentication token and user ID upon successful login.

### Properties
- `Token` (string): The JWT authentication token.
- `userId` (string): The ID of the authenticated user.

### Methods
*(None explicitly defined)*

---

## Class: UserPatchDTO

### Overview
`UserPatchDTO` is used for partially updating user settings.

### Properties
- `NameVisible` (bool, nullable): Optional update for whether artefact names should be shown by default for the user.
- `FieldCount` (int, nullable): Optional update for the number of fields/columns in the linear layout for the user.

### Methods
*(None explicitly defined)*

---

## Internal Imports
- `VTA.Data.Models` (for `UserRole`)
- `VTA.API.DTOs` (for `CategoryGetDTO` implicitly)

## Notable Packages
*(None beyond standard C# libraries)*
