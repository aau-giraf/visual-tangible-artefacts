# Class: ArtifactAddedPayload

**Path:** `Backend/SyncService/Models/ArtifactAdded/ArtifactAddedPayload.cs`

## Overview
The `ArtifactAddedPayload` class serves as a data transfer object within the `SyncService` for conveying detailed information about an artifact that has been added to a board. This payload is typically part of an `ArtifactAddedEvent` and contains all necessary data for clients to display or process the new artifact's state and visual properties.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `ArtefactId` (string, required): The unique identifier of the artefact that was added.
- `BoardId` (string, required): The unique identifier of the board to which the artefact was added.
- `ArtefactImage` (string, nullable): The URL or path to the image of the artefact.
- `ArtefactSound` (string, nullable): The URL or path to the sound associated with the artefact.
- `ArtefactWidth` (float): The width of the artefact on the board.
- `ArtefactHeight` (float): The height of the artefact on the board.
- `ArtefactPosX` (float): The X-position of the artefact on the board.
- `ArtefactPosY` (float): The Y-position of the artefact on the board.

## Methods
*(None explicitly defined)*

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard C# libraries)*
