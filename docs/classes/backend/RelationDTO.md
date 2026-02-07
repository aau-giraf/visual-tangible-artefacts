# Classes: CreatePairingRequest, PairingGetDTO

**Path:** `Backend/VTA.API/DTOs/RelationDTO.cs`

## Overview
This file defines Data Transfer Objects (DTOs) used for handling caregiver-child pairing requests and for retrieving detailed pairing information.

---

## Class: CreatePairingRequest

### Overview
`CreatePairingRequest` is a DTO used when creating a new pairing between a caregiver and a child.

### Properties
- `CaregiverId` (string, required): The unique identifier of the caregiver.
- `ChildId` (string, required): The unique identifier of the child.

### Methods
*(None explicitly defined)*

---

## Class: PairingGetDTO

### Overview
`PairingGetDTO` is a DTO used for returning detailed information about a caregiver-child pairing, including nested `UserGetDTO`s for both participants.

### Properties
- `Id` (string): The unique identifier of the pairing.
- `CaregiverId` (string): The unique identifier of the caregiver in the pairing.
- `ChildId` (string): The unique identifier of the child in the pairing.
- `Caregiver` (`UserGetDTO`, nullable): Detailed information about the caregiver.
- `Child` (`UserGetDTO`, nullable): Detailed information about the child.
- `CreatedAt` (DateTime): The date and time when the pairing was created.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(Implicitly, `UserGetDTO` is expected to be in the `VTA.API.DTOs` namespace.)*

## Notable Packages
*(None beyond standard C# libraries)*
