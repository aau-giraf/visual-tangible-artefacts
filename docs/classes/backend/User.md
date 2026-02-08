# Class: User

**Path:** `Backend/VTA.Data/Models/User.cs`

## Overview
The `User` class represents a user in the system, storing their authentication details, personal information, role, and associated data such as artefacts, categories, saved boards, and relationships.

## Properties
- `Id` (string, required): A unique identifier for the user.
- `Name` (string, nullable): The display name of the user.
- `Password` (string, required): The hashed password for the user's account.
- `Username` (string): The unique username for logging in.
- `NameVisible` (bool): Indicates if the user's name should be visible. Defaults to `false`.
- `FieldCount` (int): A configurable field count, potentially for UI layouts. Defaults to `4`.
- `Role` (UserRole): The role of the user (e.g., Child, Caregiver, Admin). Defaults to `UserRole.Child`.
- `Artefacts` (`ICollection<Artefact>`): A collection of artefacts created or owned by the user.
- `Categories` (`ICollection<Category>`): A collection of categories created or owned by the user.
- `SavedBoards` (`ICollection<SavedBoard>`): A collection of boards saved by the user.
- `CaregiverRelations` (`ICollection<Relation>`): A collection of relationships where this user acts as a caregiver.
- `ChildRelations` (`ICollection<Relation>`): A collection of relationships where this user acts as a child.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Enums: `UserRole`
- Associated Classes: `Artefact`, `Category`, `SavedBoard`, `Relation`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*