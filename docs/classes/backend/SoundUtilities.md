# Static Class: SoundUtilities

**Path:** `Backend/VTA.API/Utilities/SoundUtilities.cs`

## Overview
The `SoundUtilities` static class provides helper methods for managing sound files within the application's file system. It supports adding sound files from both `IFormFile` (uploaded files) and raw byte data, and for deleting existing sound files, organizing them by user.

## Extends
*(None, this is a static utility class)*

## Implements
*(None)*

## Properties
- `BaseAssetsPath` (static, readonly string): Stores the base directory path for all assets, initialized once to `Path.Combine(Directory.GetCurrentDirectory(), "Assets")`.
- `_Dir` (static string): A private static field indicating the subdirectory name for sounds, which is "Sounds".

## Methods

### `AddSound(IFormFile? soundFile, string soundId, string userId)`
- **Purpose**: Uploads a sound file from an `IFormFile` to the file system, storing it in a user-specific "Sounds" directory.
- **Parameters**:
  - `soundFile` (`IFormFile?`): The uploaded sound file.
  - `soundId` (string): The ID of the sound (or entity) associated with the file. This is used in the filename.
  - `userId` (string): The ID of the user, used to create a user-specific folder for organization.
- **Returns**: A string representing the API endpoint path to the saved sound file, or `null` if the input sound file is `null` or empty.

### `AddSound(byte[]? soundData, string soundId, string userId, string fileExtension = ".mp3")`
- **Purpose**: Saves raw byte data as a sound file to the file system, storing it in a user-specific "Sounds" directory.
- **Parameters**:
  - `soundData` (`byte[]?`): The raw byte array of the sound data.
  - `soundId` (string): The ID of the sound (or entity) associated with the data.
  - `userId` (string): The ID of the user for organization.
  - `fileExtension` (string): The file extension for the saved sound (defaults to ".mp3").
- **Returns**: A string representing the API endpoint path to the saved sound file, or `null` if the input sound data is `null` or empty.

### `DeleteSound(string soundId, string userId)`
- **Purpose**: Deletes a specific sound file from the file system.
- **Parameters**:
  - `soundId` (string): The ID of the sound, used to find the file (e.g., "sound_{soundId}.mp3").
  - `userId` (string): The ID of the user, used to locate the user-specific folder.
- **Returns**: `true` if the sound was successfully deleted, `null` if the sound file was not found.

## Internal Imports
*(None apparent from the snippet, uses standard .NET types)*

## Notable Packages
*(None beyond standard C# libraries)*
