# Classes: CategoryPostDTO, CategoryPatchDTO, CategoryGetDTO

**Path:** `Backend/VTA.API/DTOs/CategoryDTO.cs`

## Overview
This file defines Data Transfer Objects (DTOs) used for various operations related to managing categories, including creating new categories, updating existing ones, and retrieving category data with associated artefacts.

---

## Class: CategoryPostDTO

### Overview
`CategoryPostDTO` is used for creating a new category, allowing the submission of a name, an optional index, and an image file.

### Properties
- `CategoryId` (string, nullable): The ID of the category. If not provided, a new GUID will be generated.
- `CategoryIndex` (byte, nullable): The index of the category, potentially for ordering.
- `UserId` (string, required): The ID of the user who owns the category.
- `Name` (string, nullable): The name of the category.
- `Image` (`IFormFile`, nullable): The image file for the category.

### Methods
*(None explicitly defined)*

---

## Class: CategoryPatchDTO

### Overview
`CategoryPatchDTO` is used for updating an existing category, allowing partial updates to its name, index, and image.

### Properties
- `CategoryId` (string): The ID of the category to update.
- `CategoryIndex` (byte, nullable): The new index of the category.
- `Name` (string, nullable): The new name of the category.
- `Image` (`IFormFile`, nullable): The new image file for the category.

### Methods
*(None explicitly defined)*

---

## Class: CategoryGetDTO

### Overview
`CategoryGetDTO` is used for returning detailed category data from the API, including usage statistics and a collection of associated artefacts.

### Properties
- `CategoryId` (string): The unique identifier of the category.
- `CategoryIndex` (byte, nullable): The index of the category.
- `Name` (string, nullable): The name of the category.
- `ImageUrl` (string, nullable): The URL to the category's image.
- `UsageCount` (int): A counter for how many times this category has been used. Defaults to `0`.
- `LastUsedDate` (DateTime, nullable): The date and time when the category was last accessed or used.
- `Artefacts` (`ICollection<ArtefactGetDTO>`): A collection of `ArtefactGetDTO` objects belonging to this category.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(Implicitly, `ArtefactGetDTO` is expected to be in the `VTA.API.DTOs` namespace.)*

## Notable Packages
*(None beyond standard C# libraries)*
