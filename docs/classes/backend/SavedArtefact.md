# Class: SavedArtefact

**Path:** `Backend/VTA.Data/Models/SavedArtefact.cs`

## Overview
The `SavedArtefact` class represents an instance of an `Artefact` placed on a `SavedBoard`. It stores positional and size data for the artefact on the board, along with a reference to the original artefact and the board it's on.

## Properties
- `Id` (string, required): A unique identifier for this saved instance of an artefact on a board.
- `ArtefactId` (string, required): The ID of the base `Artefact` that this instance represents.
- `BoardId` (string, required): The ID of the `SavedBoard` this artefact is placed on.
- `PosX` (float): The X-coordinate of the artefact's position on the board. Defaults to `0`.
- `PosY` (float): The Y-coordinate of the artefact's position on the board. Defaults to `0`.
- `Width` (float): The width of the artefact instance on the board. Defaults to `200`.
- `Height` (float): The height of the artefact instance on the board. Defaults to `200`.
- `CreatedDate` (DateTime): The date and time when this saved artefact instance was created. Defaults to `DateTime.UtcNow`.
- `NameVisible` (bool, nullable): Indicates whether the name of this specific artefact instance should be visible on the board.
- `Artefact` (`virtual Artefact`): Navigation property to the base `Artefact` object.
- `Board` (`virtual SavedBoard`): Navigation property to the `SavedBoard` object this artefact is associated with.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Classes: `Artefact`, `SavedBoard`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*
