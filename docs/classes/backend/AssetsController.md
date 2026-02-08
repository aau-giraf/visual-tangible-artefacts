# Class: AssetsController

**Path:** `Backend/VTA.API/Controllers/AssetsController.cs`

## Overview
The `AssetsController` is an API controller responsible for serving static media files (images and sounds) directly from the server's file system. It provides endpoints to retrieve artefact images, category images, and sound files, organized by user. All endpoints are protected by JWT authentication at the class level.

## Security Remark
The code comments explicitly state: "All endpoints in here simply serves the image to the client. We have not done a test on if a user is allowed to access this image (it could be sensitive info or people in pictures you know), we probably should do this though". This highlights a critical security vulnerability: there is currently no authorization check to ensure that the authenticated user is permitted to access the requested asset (e.g., that `userId` in the route matches the authenticated user's ID, or that the asset is public/shared). Any authenticated user can request assets belonging to any other user if they know the `userId` and `filename`.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
*(None explicitly defined)*

## Constructor
*(Uses an implicit default constructor)*

## Methods

### `GetArtefactImage(string userId, string filename)`
- **Route**: `GET api/Assets/Artefacts/{userId}/{filename}`
- **Authorization**: `[Authorize]`
- **Purpose**: Serves an artefact image file from the file system.
- **Parameters**:
  - `userId` (string): The ID of the user who owns the artefact (used in the file path).
  - `filename` (string): The filename of the artefact image.
- **Returns**: `IActionResult`
  - `200 OK`: Returns the image file with `image/jpeg` content type.
  - `404 Not Found`: If the image file does not exist on the server.
- **Functionality**:
  - Constructs the full file system path using `Directory.GetCurrentDirectory()`, "Assets", "Artefacts", `userId`, and `filename`.
  - Checks if the file exists.
  - Reads all bytes from the file and returns them as an `image/jpeg` file.

### `GetCategoryImage(string userId, string filename)`
- **Route**: `GET api/Assets/Categories/{userId}/{filename}`
- **Authorization**: `[Authorize]`
- **Purpose**: Serves a category image file from the file system.
- **Parameters**:
  - `userId` (string): The ID of the user who owns the category (used in the file path).
  - `filename` (string): The filename of the category image.
- **Returns**: `IActionResult`
  - `200 OK`: Returns the image file with `image/jpeg` content type.
  - `404 Not Found`: If the image file does not exist on the server.
- **Functionality**:
  - Constructs the full file system path using `Directory.GetCurrentDirectory()`, "Assets", "Categories", `userId`, and `filename`.
  - Checks if the file exists.
  - Reads all bytes from the file and returns them as an `image/jpeg` file.

### `GetSoundFile(string userId, string filename)`
- **Route**: `GET api/Assets/Sounds/{userId}/{filename}`
- **Authorization**: `[Authorize]`
- **Purpose**: Serves a sound file from the file system.
- **Parameters**:
  - `userId` (string): The ID of the user who owns the sound (used in the file path).
  - `filename` (string): The filename of the sound file.
- **Returns**: `IActionResult`
  - `200 OK`: Returns the sound file with `audio/mpeg` content type.
  - `404 Not Found`: If the sound file does not exist on the server.
- **Functionality**:
  - Constructs the full file system path using `Directory.GetCurrentDirectory()`, "Assets", "Sounds", `userId`, and `filename`.
  - Checks if the file exists.
  - Reads all bytes from the file and returns them as an `audio/mpeg` file.

## Internal Imports
*(None apparent from the snippet, uses standard .NET types)*

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.CodeAnalysis.CSharp.Syntax` (appears in `using` but is unused in the provided snippet)
