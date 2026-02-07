# Class: AddArtefactArgs

**Path:** `Backend/SyncService/Models/ArtifactAdded/AddArtefactArgs.cs`

## Overview
The `AddArtefactArgs` class is a data transfer object used to pass arguments when adding an artefact to a board, typically within a real-time communication context like SignalR. It specifies the unique identifiers of the artefact, the target board, the owning user, and the initial position of the artefact on the board.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `ArtefactId` (string, required): The unique identifier of the artefact to be added.
- `BoardId` (string, required): The unique identifier of the board to which the artefact will be added.
- `UserId` (string, required): The unique identifier of the user who owns the artefact and the board.
- `PosX` (float, required): The X-coordinate for the artefact's initial position on the board.
- `PosY` (float, required): The Y-coordinate for the artefact's initial position on the board.

## Methods
*(None explicitly defined)*

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
*(None beyond standard C# libraries)*
