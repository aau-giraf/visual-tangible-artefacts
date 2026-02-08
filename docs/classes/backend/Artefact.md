# Class: Artefact

**Path:** `Backend/VTA.Data/Models/Artefact.cs`

## Overview
The `Artefact` class represents a digital artifact within the system, linking it to a user and potentially a category. It stores information about the artifact's media (image, sound), metadata (name, modification date), and its index.

## Properties
- `ArtefactId` (string, required): A unique identifier for the artefact.
- `ArtefactIndex` (ushort, required): An index for the artefact, likely used for ordering or display within a collection.
- `UserId` (string, required): The ID of the user who owns this artefact.
- `CategoryId` (string, nullable): The ID of the category this artefact belongs to. Can be null if not categorized.
- `ImagePath` (string, nullable): The path to the image file associated with the artefact.
- `SoundPath` (string, nullable): The path to the sound file associated with the artefact.
- `ModifiedDate` (DateTime, nullable): The date and time when the artefact was last modified.
- `Name` (string, nullable): The display name of the artefact.
- `NameShown` (bool, nullable): Indicates whether the artefact's name should be displayed.
- `Category` (`virtual Category`, nullable): Navigation property to the associated `Category` object.
- `User` (`virtual User`): Navigation property to the `User` object who owns this artefact.
- `SavedArtefacts` (`ICollection<SavedArtefact>`): A collection of `SavedArtefact` entries associated with this artefact, linking it to saved boards.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Classes: `Category`, `User`, `SavedArtefact`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*