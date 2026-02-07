# Static Class: ImageUtilities

**Path:** `Backend/VTA.API/Utilities/ImageUtilities.cs`

## Overview
The `ImageUtilities` static class provides a set of helper methods for managing image files within the application's file system, including adding, deleting, and locating images. It organizes images into user-specific directories.

## Extends
*(None, this is a static utility class)*

## Implements
*(None)*

## Properties
- `BaseAssetsPath` (static, readonly string): Stores the base directory path for all assets, initialized once to `Path.Combine(Directory.GetCurrentDirectory(), "Assets")`.
- `_Dir` (static string): A private static field used to temporarily store the subdirectory name (e.g., "Artefact" or "Category") during operations.

## Methods

### `AddImage(IFormFile? image, string artefactId, string dir, string userId)`
- **Purpose**: Uploads an image file to the file system, storing it in a structured folder based on the user and directory type.
- **Parameters**:
  - `image` (`IFormFile?`): The uploaded image file.
  - `artefactId` (string): The ID of the artefact (or entity) associated with the image. This is used in the filename.
  - `dir` (string): The subdirectory name (e.g., "Artefact" or "Category") under `Assets`.
  - `userId` (string): The ID of the user, used to create a user-specific folder for organization.
- **Returns**: A string representing the API endpoint path to the saved image, or `null` if the input image is `null` or empty.

### `DeleteImage(string imgName, string dir, string userId)`
- **Purpose**: Deletes a specific image file from the file system.
- **Parameters**:
  - `imgName` (string): The unique identifier (GUID) of the owning entity (e.g., artefact ID), used to find the file.
  - `dir` (string): The subdirectory name (e.g., "Artefact" or "Category") where the image is stored.
  - `userId` (string): The ID of the user, used to locate the user-specific folder.
- **Returns**: `true` if the image was successfully deleted, `null` if the image file was not found.

### `FindFile(string fileName, string userId)` (private)
- **Purpose**: Locates an image file in the user-specific directory and returns its full filename (including extension) if found.
- **Parameters**:
  - `fileName` (string): The base name of the file to search for (expected to be the entity's GUID).
  - `userId` (string): The ID of the user, used to search within their directory.
- **Returns**: The full filename of the found image, or `null` if not found or an error occurs.

### `GetFileType(IFormFile file)` (private)
- **Purpose**: Attempts to determine the file type (e.g., "png", "jpeg") by reading its magic numbers (file signature).
- **Parameters**:
  - `file` (`IFormFile`): The file for which to determine the type.
- **Returns**: A string representing the detected file type (e.g., "png", "jpeg"), or `null` if the signature is not recognized.
- **Note**: The comment indicates this method was added by a frontend developer but not used due to an oversight in post requests.

## Internal Imports
*(None apparent from the snippet, uses standard .NET types)*

## Notable Packages
- `Microsoft.IdentityModel.Tokens` (appears in `using` directives but is not used in the provided snippet and seems unrelated to image utilities.)
