# Classes: FileChangeDTO, SyncResponseDTO, SyncSummaryDTO

**Path:** `Backend/VTA.API/DTOs/SyncDTO.cs`

## Overview
This file defines Data Transfer Objects (DTOs) used for various synchronization operations within the VTA API, including reporting file changes and summarizing synchronization results.

---

## Class: FileChangeDTO

### Overview
`FileChangeDTO` represents details about a changed file, used to inform clients about updates to resources.

### Properties
- `FileId` (string, required): The unique identifier of the changed file or resource.
- `FileName` (string, required): The name of the changed file.
- `FileType` (string, required): The type of the file (e.g., "artefact", "category", "board").
- `ModifiedDate` (DateTime, nullable): The last modification date of the file.
- `ImageUrl` (string, nullable): A URL to the image, if the file is an image.
- `SoundUrl` (string, nullable): A URL to the sound, if the file is a sound.

### Methods
*(None explicitly defined)*

---

## Class: SyncResponseDTO

### Overview
`SyncResponseDTO` encapsulates the detailed response of a synchronization request, listing all changed files and providing a timestamp.

### Properties
- `ChangedFiles` (`List<FileChangeDTO>`, required): A list of `FileChangeDTO` objects detailing each file that has changed.
- `CheckDate` (DateTime): The timestamp when the synchronization check was performed.
- `TotalChanges` (int): The total number of changes detected.

### Methods
*(None explicitly defined)*

---

## Class: SyncSummaryDTO

### Overview
`SyncSummaryDTO` provides a summarized overview of synchronization changes, breaking down changes by type and including a check date.

### Properties
- `TotalChanges` (int): The total count of changes across all types.
- `ArtefactChanges` (int): The number of changes related to artefacts.
- `BoardChanges` (int): The number of changes related to boards.
- `CheckDate` (DateTime): The timestamp when the synchronization check was performed.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(None apparent from the snippet, assuming `List` and `required` are C# built-ins)*

## Notable Packages
*(None beyond standard C# libraries)*
