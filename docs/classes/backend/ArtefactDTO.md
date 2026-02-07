# Classes: ArtefactPostDTO, ArtefactPatchDTO, ArtefactGetDTO, SimpleTtsRequest, ArtefactTtsRequest, StandaloneTtsRequest, ArtefactTextToSpeechDTO, BulkUpdateNameShownDTO

**Path:** `Backend/VTA.API/DTOs/ArtefactDTO.cs`

## Overview
This file defines several Data Transfer Objects (DTOs) used for various operations related to artefacts, including creation, updating, retrieval, and text-to-speech generation.

---

## Class: ArtefactPostDTO

### Overview
`ArtefactPostDTO` is used for creating a new artefact, allowing the submission of image and sound files along with artefact metadata.

### Properties
- `ArtefactId` (string, nullable): The ID of the artefact. If not provided, a new GUID will be generated.
- `ArtefactIndex` (ushort): The index of the artefact.
- `UserId` (string, required): The ID of the user who owns the artefact.
- `CategoryId` (string, nullable): The category ID the artefact belongs to.
- `Name` (string, nullable): The name of the artefact.
- `NameShown` (bool, nullable): Whether the artefact name should be shown.
- `Image` (`IFormFile`, required): The image file for the artefact.
- `Sound` (`IFormFile`, nullable): The sound file for the artefact.

### Methods
*(None explicitly defined)*

---

## Class: ArtefactPatchDTO

### Overview
`ArtefactPatchDTO` is used for updating an existing artefact, supporting partial updates for its properties and associated media files.

### Properties
- `ArtefactId` (string, required): The ID of the artefact to update.
- `ArtefactIndex` (ushort, nullable): The index of the artefact.
- `UserId` (string, required): The ID of the user who owns the artefact.
- `CategoryId` (string, nullable): The category ID the artefact belongs to.
- `Name` (string, nullable): The name of the artefact.
- `NameShown` (bool, nullable): Whether the artefact name should be shown.
- `Image` (`IFormFile`, nullable): The image file for the artefact (optional for update).
- `Sound` (`IFormFile`, nullable): The sound file for the artefact (optional for update).

### Methods
*(None explicitly defined)*

---

## Class: ArtefactGetDTO

### Overview
`ArtefactGetDTO` is used for returning artefact data from the API, including URLs for its image and sound.

### Properties
- `ArtefactId` (string): The unique identifier of the artefact. (`JsonPropertyName("artefactId")`)
- `ArtefactIndex` (ushort): The index of the artefact.
- `UserId` (string): The ID of the user who owns the artefact.
- `CategoryId` (string, nullable): The category ID the artefact belongs to.
- `Name` (string, nullable): The name of the artefact.
- `NameShown` (bool, nullable): Whether the artefact's name should be shown.
- `ImageUrl` (string, nullable): The URL to the artefact's image. (`JsonPropertyName("imageUrl")`)
- `SoundUrl` (string, nullable): The URL to the artefact's sound. (`JsonPropertyName("soundUrl")`)

### Methods
*(None explicitly defined)*

---

## Class: SimpleTtsRequest

### Overview
`SimpleTtsRequest` is a DTO for generating text-to-speech without requiring an existing artefact.

### Properties
- `Text` (string, required): The text to convert to speech.
- `VoiceId` (string, nullable): The ElevenLabs voice ID to use (optional).

### Methods
*(None explicitly defined)*

---

## Class: ArtefactTtsRequest

### Overview
`ArtefactTtsRequest` is a DTO for generating text-to-speech and saving the generated audio to an existing artefact.

### Properties
- `ArtefactId` (string, required): The ID of the artefact to add the generated speech to.
- `Text` (string, required): The text to convert to speech.
- `VoiceId` (string, nullable): The ElevenLabs voice ID to use (optional).

### Methods
*(None explicitly defined)*

---

## Class: StandaloneTtsRequest

### Overview
`StandaloneTtsRequest` is a DTO for generating text-to-speech and saving the audio with an auto-generated ID, separate from an existing artefact.

### Properties
- `Text` (string, required): The text to convert to speech.
- `VoiceId` (string, nullable): The ElevenLabs voice ID to use (optional).

### Methods
*(None explicitly defined)*

---

## Class: ArtefactTextToSpeechDTO

### Overview
`ArtefactTextToSpeechDTO` is a comprehensive DTO for generating text-to-speech for an artefact, allowing fine-grained control over voice settings.

### Properties
- `ArtefactId` (string, required): The ID of the artefact to generate speech for.
- `Text` (string, required): The text to convert to speech.
- `VoiceId` (string, nullable): The ElevenLabs voice ID to use (optional).
- `ModelId` (string, nullable): The ElevenLabs model ID to use (optional).
- `Stability` (double, nullable): Voice stability setting (0.0 to 1.0).
- `SimilarityBoost` (double, nullable): Voice similarity boost setting (0.0 to 1.0).
- `UseSpeakerBoost` (bool, nullable): Whether to use speaker boost.

### Methods
*(None explicitly defined)*

---

## Class: BulkUpdateNameShownDTO

### Overview
`BulkUpdateNameShownDTO` is a DTO for bulk updating the `NameShown` property across multiple artefacts belonging to a user.

### Properties
- `NameShown` (bool, required): The `NameShown` value to apply to all artefacts.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(Implicitly, `IFormFile` is from `Microsoft.AspNetCore.Http` which is a common ASP.NET Core type, not an internal import in `VTA.API.DTOs` namespace.)*

## Notable Packages
- `System.Text.Json.Serialization` (for `JsonPropertyName` attribute in `ArtefactGetDTO`)
