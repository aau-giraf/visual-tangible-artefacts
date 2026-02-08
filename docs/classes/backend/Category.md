# Class: Category

**Path:** `Backend/VTA.Data/Models/Category.cs`

## Overview
The `Category` class represents a grouping mechanism for `Artefact` objects, owned by a specific `User`. It includes metadata such as name, image, usage statistics, and a collection of associated artefacts.

## Properties
- `CategoryId` (string, required): A unique identifier for the category.
- `CategoryIndex` (byte, nullable): An index for ordering categories, if applicable.
- `UserId` (string, required): The ID of the user who owns this category.
- `Name` (string, nullable): The display name of the category.
- `ImagePath` (string, nullable): The path to an image representing the category.
- `ModifiedDate` (DateTime, nullable): The date and time when the category was last modified.
- `UsageCount` (int): A counter for how many times this category has been used. Defaults to `0`.
- `LastUsedDate` (DateTime, nullable): The date and time when the category was last accessed or used.
- `Artefacts` (`ICollection<Artefact>`): A collection of `Artefact` objects that belong to this category.
- `User` (`virtual User`): Navigation property to the `User` object who owns this category.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Classes: `Artefact`, `User`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*