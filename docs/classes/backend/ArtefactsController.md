# Class: ArtefactsController

**Path:** `Backend/VTA.API/Controllers/ArtefactsController.cs`

## Overview
The `ArtefactsController` is an API controller dedicated to managing user-owned artefacts. It provides endpoints for creating, retrieving, updating, and deleting artefacts, as well as integrating with the ElevenLabs Text-to-Speech (TTS) service to generate and associate audio with artefacts. All endpoints are protected by JWT authentication at the class level.

## Extends
- `ControllerBase`

## Implements
*(None)*

## Properties
- `AllowedVoiceIds` (private static readonly `HashSet<string>`): A set of predefined voice IDs that are permitted for use with the ElevenLabs service, including a default Danish voice.

## Constructor

### `ArtefactsController(VTAContext context)`
- **Purpose**: Initializes a new instance of the `ArtefactsController`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for interacting with artefact and related data.

## Methods

### `GetArtefacts()`
- **Route**: `GET api/Artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves all artefacts owned by the currently authenticated user.
- **Parameters**: None
- **Returns**: `ActionResult<IEnumerable<ArtefactGetDTO>>`
  - `200 OK`: Returns a list of `ArtefactGetDTO` objects belonging to the user.
  - `404 Not Found`: If no artefacts are found for the user.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Queries the database for artefacts matching the `userId`.
  - Maps `Artefact` entities to `ArtefactGetDTO`s using `DTOConverter`.

### `GetArtefact(string artefactId)`
- **Route**: `GET api/Artefacts/{artefactId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Retrieves a specific artefact owned by the authenticated user.
- **Parameters**:
  - `artefactId` (string): The unique identifier of the artefact to retrieve.
- **Returns**: `ActionResult<ArtefactGetDTO>`
  - `200 OK`: Returns the `ArtefactGetDTO` for the specified artefact.
  - `404 Not Found`: If the artefact is not found or is not owned by the user.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Queries the database for the artefact by `artefactId` and `userId`.
  - Maps the `Artefact` entity to an `ArtefactGetDTO`.

### `PatchArtefact([FromForm] ArtefactPatchDTO dto)`
- **Route**: `PATCH api/Artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Partially updates an existing artefact's information, including its metadata, image, and sound file.
- **Parameters**:
  - `dto` (`ArtefactPatchDTO`): An object containing the fields to be updated, submitted as form data.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful update.
  - `401 Unauthorized`: If the user ID is not found in the token.
  - `400 Bad Request`: If the artefact specified in the DTO is not found.
  - `404 Not Found`: If the artefact does not exist (during concurrency handling).
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Retrieves the artefact by `ArtefactId` from the DTO.
  - Updates `ArtefactIndex`, `Name`, and `NameShown` if provided in the DTO.
  - Handles image updates: deletes the old image using `ImageUtilities.DeleteImage` (using `CategoryId` as the identifier, which seems incorrect as it should be `ArtefactId` for Artefact images) and adds the new image using `ImageUtilities.AddImage`.
  - Handles sound updates: deletes the old sound using `SoundUtilities.DeleteSound` and adds the new sound using `SoundUtilities.AddSound`.
  - Marks the artefact entity as `Modified` and saves changes to the database, handling `DbUpdateConcurrencyException`.
- **Remarks**: The usage of `artefact.CategoryId` for `ImageUtilities.DeleteImage` when updating an artefact's image might be a bug, as `ArtefactId` should likely be used instead for artefact images.

### `PostArtefact(ArtefactPostDTO artefactPostDTO)`
- **Route**: `POST api/Artefacts`
- **Authorization**: `[Authorize]`
- **Purpose**: Creates a new artefact or updates an existing one if `ArtefactId` is provided. Handles file uploads for images and sounds.
- **Parameters**:
  - `artefactPostDTO` (`ArtefactPostDTO`): An object with all artefact information, submitted as form data.
- **Returns**: `ActionResult<ArtefactGetDTO>`
  - `200 OK`: Returns the created or updated `ArtefactGetDTO`.
  - `403 Forbidden`: If the authenticated user's ID does not match the `UserId` in the DTO.
  - `401 Unauthorized`: If the user is not found.
  - `409 Conflict`: If an ID collision occurs during creation (extremely rare).
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Verifies that the `userId` matches the `ArtefactPostDTO.UserId`.
  - Checks if `artefactPostDTO.ArtefactId` is provided; if so, attempts to update an existing artefact.
  - For new artefacts, generates a new `Guid` for `ArtefactId`.
  - Handles image and sound file uploads using `ImageUtilities.AddImage` and `SoundUtilities.AddSound`, deleting old files if present during updates.
  - Sets `artefact.NameShown` based on `artefactPostDTO.NameShown` or the user's default `NameVisible` setting.
  - Adds the new artefact to the context or updates the existing one.
  - Saves changes, handling `DbUpdateException` for ID conflicts.
  - Maps the resulting `Artefact` to `ArtefactGetDTO`.

### `DeleteArtefact(string artefactId)`
- **Route**: `DELETE api/Artefacts/{artefactId}`
- **Authorization**: `[Authorize]`
- **Purpose**: Deletes a specific artefact and its associated image and sound files from the file system.
- **Parameters**:
  - `artefactId` (string): The unique identifier of the artefact to delete.
- **Returns**: `IActionResult`
  - `204 No Content`: On successful deletion.
  - `403 Forbidden`: If the authenticated user does not own the artefact.
  - `404 Not Found`: If the artefact does not exist.
- **Functionality**:
  - Extracts the `userId` from the JWT.
  - Finds the artefact by `artefactId`.
  - Verifies user ownership of the artefact.
  - Deletes the associated image and sound files using `ImageUtilities.DeleteImage` and `SoundUtilities.DeleteSound`.
  - Removes the artefact from the context and saves changes.

### `GenerateSpeechSimple([FromBody] SimpleTtsRequest request)`
- **Route**: `POST api/Artefacts/generate-speech-simple`
- **Authorization**: `[Authorize]`
- **Purpose**: Generates speech from text using the ElevenLabs API and returns the audio data directly, without associating it with an artefact.
- **Parameters**:
  - `request` (`SimpleTtsRequest`): Contains the text to convert and an optional voice ID.
- **Returns**: `IActionResult`
  - `200 OK`: Returns the audio file (`audio/mpeg`).
  - `400 Bad Request`: If the text is empty.
  - `500 Internal Server Error`: If the ElevenLabs API key is not configured or speech generation fails.
- **Functionality**:
  - Validates the input text.
  - Retrieves the ElevenLabs API key from configuration.
  - Creates an `ElevenLabsService` instance.
  - Resolves the voice ID using `ResolveVoiceId`.
  - Calls `elevenLabsService.GenerateSpeechAsync` with default model and Danish language code.
  - Returns the generated audio as a file.

### `GenerateSpeechAndSave([FromBody] ArtefactTtsRequest request)`
- **Route**: `POST api/Artefacts/generate-speech-and-save`
- **Authorization**: `[Authorize]`
- **Purpose**: Generates speech from text using the ElevenLabs API and saves the generated audio to an existing artefact.
- **Parameters**:
  - `request` (`ArtefactTtsRequest`): Contains the artefact ID, text to convert, and an optional voice ID.
- **Returns**: `IActionResult`
  - `200 OK`: Returns an object with the new `soundUrl`.
  - `400 Bad Request`: If text or artefact ID are empty.
  - `403 Forbidden`: If the user does not own the artefact.
  - `404 Not Found`: If the artefact does not exist.
  - `500 Internal Server Error`: If ElevenLabs API key is not configured, speech generation fails, or saving audio fails.
- **Functionality**:
  - Validates input.
  - Extracts `userId` from JWT and verifies ownership of the artefact.
  - Retrieves ElevenLabs API key and creates `ElevenLabsService`.
  - Resolves voice ID using `ResolveVoiceId`.
  - Generates speech.
  - Saves the audio data using `SoundUtilities.AddSound` (overwrites existing sound).
  - Updates the artefact's `SoundPath` in the database and saves changes.

### `GenerateAndSaveSpeech([FromBody] StandaloneTtsRequest request)`
- **Route**: `POST api/Artefacts/generate-and-save-speech`
- **Authorization**: `[Authorize]`
- **Purpose**: Generates speech from text and saves it as a standalone audio file with a unique ID, not directly linked to an existing artefact.
- **Parameters**:
  - `request` (`StandaloneTtsRequest`): Contains the text to convert and an optional voice ID.
- **Returns**: `IActionResult`
  - `200 OK`: Returns an object with the generated `soundId`, `soundUrl`, and `audioSize`.
  - `400 Bad Request`: If the text is empty.
  - `401 Unauthorized`: If the user ID is not found in the token.
  - `500 Internal Server Error`: If ElevenLabs API key is not configured, speech generation fails, or saving audio fails.
- **Functionality**:
  - Validates input.
  - Extracts `userId` from JWT.
  - Retrieves ElevenLabs API key and creates `ElevenLabsService`.
  - Resolves voice ID using `ResolveVoiceId`.
  - Generates speech.
  - Generates a new `Guid` for `soundId`.
  - Saves the audio data using `SoundUtilities.AddSound`.

### `PlayArtefactAudio(string artefactId)`
- **Route**: `GET api/Artefacts/{artefactId}/play-audio`
- **Authorization**: `[Authorize]`
- **Purpose**: Serves the audio file associated with a specific artefact.
- **Parameters**:
  - `artefactId` (string): The ID of the artefact whose audio is to be played.
- **Returns**: `IActionResult`
  - `200 OK`: Returns the audio file (`audio/mpeg`).
  - `404 Not Found`: If the artefact is not found, not owned by the user, or has no audio attached.
  - `500 Internal Server Error`: For other internal errors.
- **Functionality**:
  - Extracts `userId` from JWT and verifies artefact ownership.
  - Checks if `artefact.SoundPath` is present.
  - Converts the stored API path (`artefact.SoundPath`) to a file system path.
  - Reads the audio file bytes and returns them as `audio/mpeg`.

### `GenerateSpeech(ArtefactTextToSpeechDTO ttsDto)`
- **Route**: `POST api/Artefacts/generate-speech`
- **Authorization**: `[Authorize]`
- **Purpose**: Generates speech from text using the ElevenLabs API with advanced settings and updates an existing artefact with the generated audio.
- **Parameters**:
  - `ttsDto` (`ArtefactTextToSpeechDTO`): Contains text, voice/model IDs, and voice settings (stability, similarity boost, speaker boost).
- **Returns**: `ActionResult<ArtefactGetDTO>`
  - `200 OK`: Returns the updated `ArtefactGetDTO`.
  - `400 Bad Request`: If text is empty.
  - `403 Forbidden`: If the user does not own the artefact.
  - `404 Not Found`: If the artefact does not exist.
  - `500 Internal Server Error`: If ElevenLabs API key is not configured, speech generation fails, or saving audio fails.
- **Functionality**:
  - Extracts `userId` from JWT and verifies artefact ownership.
  - Validates input text.
  - Retrieves ElevenLabs API key and creates `ElevenLabsService`.
  - Resolves voice ID using `ResolveVoiceId`.
  - Generates speech with advanced settings.
  - Deletes any existing sound for the artefact.
  - Saves the generated audio temporarily, converts it to an `IFormFile`, and then uses `SoundUtilities.AddSound` to store it.
  - Updates the artefact's `SoundPath` and `ModifiedDate`, then saves changes.
  - Deletes the temporary audio file.
  - Returns the updated `ArtefactGetDTO`.

### `ResolveVoiceId(string? requestedVoiceId)` (private)
- **Purpose**: Determines the effective voice ID to use, falling back to a default if the requested ID is invalid or not allowed.
- **Parameters**:
  - `requestedVoiceId` (string, nullable): The voice ID requested by the client.
- **Returns**: `string` - The resolved voice ID (either the valid requested one or the default).
- **Functionality**:
  - Checks if `requestedVoiceId` is null/empty.
  - Checks if the normalized `requestedVoiceId` is in `AllowedVoiceIds`.
  - Logs warnings if an unsupported voice ID is requested.

### `IsValidVoiceId(string? voiceId)` (private)
- **Purpose**: Checks if a given voice ID is valid and allowed.
- **Parameters**:
  - `voiceId` (string, nullable): The voice ID to validate.
- **Returns**: `bool` - `true` if valid and allowed, `false` otherwise.

### `BulkUpdateNameShown([FromBody] BulkUpdateNameShownDTO request)`
- **Route**: `PATCH api/Artefacts/bulk-update-name-shown`
- **Authorization**: `[Authorize]`
- **Purpose**: Updates the `NameShown` property for all artefacts owned by the current user.
- **Parameters**:
  - `request` (`BulkUpdateNameShownDTO`): Contains the boolean value to apply to `NameShown`.
- **Returns**: `IActionResult`
  - `200 OK`: Returns an object with `updatedCount` and the applied `nameShown` value.
  - `401 Unauthorized`: If the user token is invalid.
- **Functionality**:
  - Extracts `userId` from JWT.
  - Retrieves all artefacts for the user.
  - Iterates through them, updating `NameShown`.
  - Saves changes to the database.

### `ArtefactExists(string id)` (private)
- **Purpose**: Checks if an artefact with the given ID exists in the database.
- **Parameters**:
  - `id` (string): The artefact ID to check.
- **Returns**: `bool` - `true` if an artefact with the ID exists, `false` otherwise.

## Internal Imports
- `VTA.API.DTOs`
- `VTA.API.Utilities`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.Mvc`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.Extensions.Configuration`
- `System.Net.Http`
