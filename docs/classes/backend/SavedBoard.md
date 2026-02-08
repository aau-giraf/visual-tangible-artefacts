# Class: SavedBoard

**Path:** `Backend/VTA.Data/Models/SavedBoard.cs`

## Overview
The `SavedBoard` class represents a user-saved board configuration, allowing users to save and retrieve their custom layouts of artefacts. It includes metadata about the board, references to the user, and information about the artefacts placed on it.

## Properties
- `Id` (string, required): A unique identifier for the saved board.
- `Name` (string, required): The name given to the saved board by the user.
- `UserId` (string, required): The ID of the user who owns this saved board.
- `SnapshotPath` (string, nullable): The path to an image snapshot of the board layout, if available.
- `CreatedDate` (DateTime): The date and time when the board was initially saved. Defaults to `DateTime.UtcNow`.
- `ModifiedDate` (DateTime, nullable): The date and time when the board was last modified.
- `User` (`virtual User`): Navigation property to the `User` object who owns this saved board.
- `SavedArtefactIds` (string, nullable): A JSON array string containing the IDs of `SavedArtefact` records present on this board. This allows tracking multiple instances of the same base artefact.
- `ArtefactIds` (string, nullable): A JSON array string containing the base `Artefact` IDs present on this board. Used for quick lookup and kept in sync by the controller.
- `SavedArtefacts` (`ICollection<SavedArtefact>`): A collection of `SavedArtefact` entries directly associated with this board.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Classes: `User`, `SavedArtefact`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*