# Static Class: DTOConverter

**Path:** `Backend/VTA.API/DTOs/DTOConverter.cs`

## Overview
The `DTOConverter` static class provides a collection of utility methods responsible for converting data between Entity Framework Core models (from `VTA.Data.Models`) and various Data Transfer Objects (DTOs) used by the API. This facilitates clean separation of concerns between internal data representation and external API contracts.

## Extends
*(None, this is a static utility class)*

## Implements
*(None)*

## Properties
*(None)*

## Methods

### `MapArtefactToArtefactGetDTO(Artefact artefact, string scheme, string host)`
- **Purpose**: Converts an `Artefact` data model to an `ArtefactGetDTO`.
- **Parameters**:
  - `artefact` (`Artefact`): The data model to convert.
  - `scheme` (string): The URL scheme (e.g., "http" or "https") for constructing image/sound URLs.
  - `host` (string): The host part of the URL for constructing image/sound URLs.
- **Returns**: An `ArtefactGetDTO` instance with constructed `ImageUrl` and `SoundUrl` properties.

### `MapArtefactPostDTOToArtefact(ArtefactPostDTO artefact, string id, string? imageUrl, string? soundUrl = null)`
- **Purpose**: Converts an `ArtefactPostDTO` to an `Artefact` data model, typically for new artefact creation.
- **Parameters**:
  - `artefact` (`ArtefactPostDTO`): The DTO containing new artefact data.
  - `id` (string): The ID to assign to the new `Artefact` model.
  - `imageUrl` (string, nullable): The image path for the `Artefact` model.
  - `soundUrl` (string, nullable): The sound path for the `Artefact` model.
- **Returns**: An `Artefact` data model instance.

### `MapCategoryToCategoryGetDTO(Category category, string scheme, string host)`
- **Purpose**: Converts a `Category` data model to a `CategoryGetDTO`, including its associated `ArtefactGetDTO`s.
- **Parameters**:
  - `category` (`Category`): The data model to convert.
  - `scheme` (string): The URL scheme for constructing image URLs.
  - `host` (string): The host part of the URL for constructing image URLs.
- **Returns**: A `CategoryGetDTO` instance with populated `Artefacts` and `ImageUrl`.

### `MapCategoryPostDTOToCategory(CategoryPostDTO category, string id, string imageUrl)`
- **Purpose**: Converts a `CategoryPostDTO` to a `Category` data model, typically for new category creation.
- **Parameters**:
  - `category` (`CategoryPostDTO`): The DTO containing new category data.
  - `id` (string): The ID to assign to the new `Category` model.
  - `imageUrl` (string): The image path for the `Category` model.
- **Returns**: A `Category` data model instance.

### `MapUserToUserGetDTO(User user)`
- **Purpose**: Converts a `User` data model to a `UserGetDTO`.
- **Parameters**:
  - `user` (`User`): The data model to convert.
- **Returns**: A `UserGetDTO` instance.

### `MapUserSignUpDTOToUser(UserSignupDTO dto, string id)`
- **Purpose**: Converts a `UserSignupDTO` to a `User` data model, typically for user registration.
- **Parameters**:
  - `dto` (`UserSignupDTO`): The DTO containing user signup data.
  - `id` (string): The ID to assign to the new `User` model.
- **Returns**: A `User` data model instance.

### `MapUserPostDTOToUser(UserPostDTO user, string id)`
- **Purpose**: Converts a `UserPostDTO` to a `User` data model, typically for user creation by an admin.
- **Parameters**:
  - `user` (`UserPostDTO`): The DTO containing user post data.
  - `id` (string): The ID to assign to the new `User` model.
- **Returns**: A `User` data model instance.

### `MapSavedArtefactToSavedArtefactGetDTO(SavedArtefact savedArtefact, string scheme, string host)`
- **Purpose**: Converts a `SavedArtefact` data model to a `SavedArtefactGetDTO`, recursively mapping its associated `Artefact` to `ArtefactGetDTO`.
- **Parameters**:
  - `savedArtefact` (`SavedArtefact`): The data model to convert.
  - `scheme` (string): The URL scheme for constructing image/sound URLs.
  - `host` (string): The host part of the URL for constructing image/sound URLs.
- **Returns**: A `SavedArtefactGetDTO` instance.

### `MapSavedArtefactPostDTOToSavedArtefact(SavedArtefactPostDTO dto, string id, string boardId)`
- **Purpose**: Converts a `SavedArtefactPostDTO` to a `SavedArtefact` data model, typically for placing an artefact on a board.
- **Parameters**:
  - `dto` (`SavedArtefactPostDTO`): The DTO containing saved artefact data.
  - `id` (string): The ID to assign to the new `SavedArtefact` model.
  - `boardId` (string): The ID of the board to which the artefact is being saved.
- **Returns**: A `SavedArtefact` data model instance.

## Internal Imports
- `VTA.Data.Models`

## Notable Packages
*(None beyond standard C# libraries, as the DTOs are assumed to be in the same namespace)*
