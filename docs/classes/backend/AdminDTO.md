# Classes: PairingDTO, CreatePairingDTO

**Path:** `Backend/VTA.API/DTOs/AdminDTO.cs`

## Overview
This file, despite its name `AdminDTO.cs`, defines two Data Transfer Objects (DTOs) related to pairing functionality: `PairingDTO` for representing existing pairings with associated user information, and `CreatePairingDTO` for handling the creation of new pairings.

## Class: PairingDTO

### Overview
`PairingDTO` is used to transfer detailed information about a caregiver-child pairing, including the pairing's status and the associated caregiver and child user data.

### Properties
- `Id` (string): The unique identifier of the pairing.
- `CaregiverId` (string): The ID of the caregiver involved in the pairing.
- `ChildId` (string): The ID of the child involved in the pairing.
- `IsActive` (bool): Indicates if the pairing is currently active.
- `CreatedAt` (DateTime): The timestamp when the pairing was created.
- `Caregiver` (`UserGetDTO`, nullable): Detailed information about the caregiver user.
- `Child` (`UserGetDTO`, nullable): Detailed information about the child user.

### Methods
*(None explicitly defined)*

### Relationships
- Associated Classes: `UserGetDTO`

---

## Class: CreatePairingDTO

### Overview
`CreatePairingDTO` is used as a request model for creating a new caregiver-child pairing, containing only the essential IDs required for the operation.

### Properties
- `CaregiverId` (string, required): The ID of the caregiver to be paired.
- `ChildId` (string, required): The ID of the child to be paired.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(Implicitly, `UserGetDTO` is expected to be in the `VTA.API.DTOs` namespace or explicitly imported, though not shown in the snippet)*

## Notable Packages
*(None beyond standard C# libraries)*
