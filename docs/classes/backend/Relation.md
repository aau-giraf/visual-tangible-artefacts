# Class: Relation

**Path:** `Backend/VTA.Data/Models/Relation.cs`

## Overview
The `Relation` class represents a relationship between a caregiver and a child user in the system. It facilitates tracking and managing these associations, including their active status and creation timestamp.

## Properties
- `Id` (string): A unique identifier for the relation. Defaults to a new GUID.
- `CaregiverId` (string, required): The ID of the user acting as the caregiver in this relation.
- `ChildId` (string, required): The ID of the user acting as the child in this relation.
- `IsActive` (bool): Indicates whether the relation is currently active. Defaults to `true`.
- `CreatedAt` (DateTime): The timestamp when the relation was created. Defaults to `DateTime.UtcNow`.
- `Caregiver` (`virtual User`): Navigation property to the `User` object representing the caregiver.
- `Child` (`virtual User`): Navigation property to the `User` object representing the child.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Classes: `User`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*
