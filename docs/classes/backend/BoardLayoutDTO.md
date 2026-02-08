# Classes: BoardArtefactLayoutDTO, SaveBoardRequestDTO, BoardLayoutResponseDTO, UpdateArtefactLayoutDTO

**Path:** `Backend/VTA.API/DTOs/BoardLayoutDTO.cs`

## Overview
This file defines Data Transfer Objects (DTOs) specifically designed for handling the layout of artefacts on a board, including their positions, sizes, and associated metadata for saving and updating board layouts.

---

## Class: BoardArtefactLayoutDTO

### Overview
`BoardArtefactLayoutDTO` represents the position and size information of a single artefact instance within a board's layout.

### Properties
- `SavedArtefactId` (string, nullable): The ID of the saved artefact instance (can be null when initially creating a board).
- `ArtefactId` (string, required): The ID of the base artefact.
- `PosX` (float): The X-position of the artefact on the board. Defaults to `0`.
- `PosY` (float): The Y-position of the artefact on the board. Defaults to `0`.
- `Width` (float): The width of the artefact. Defaults to `200`.
- `Height` (float): The height of the artefact. Defaults to `200`.
- `NameVisible` (bool, nullable): Per-tile flag indicating if the artefact's name should be visible. Mirrors the Flutter field `nameVisible`.

### Methods
*(None explicitly defined)*

---

## Class: SaveBoardRequestDTO

### Overview
`SaveBoardRequestDTO` is used as a request model when creating or updating an entire saved board, containing the board's name and a list of its artefacts' layout data.

### Properties
- `Name` (string, required): The name of the board.
- `Artefacts` (`List<BoardArtefactLayoutDTO>`): A list of artefacts with their positions and sizes on the board. Defaults to an empty list.

### Methods
*(None explicitly defined)*

---

## Class: BoardLayoutResponseDTO

### Overview
`BoardLayoutResponseDTO` is used to return detailed information about a board's layout, including its metadata and the layout data for all its artefacts.

### Properties
- `BoardId` (string, required): The unique identifier of the board.
- `Name` (string, required): The name of the board.
- `CreatedDate` (DateTime): The date when the board was created.
- `ModifiedDate` (DateTime, nullable): The date when the board was last modified.
- `Artefacts` (`List<BoardArtefactLayoutDTO>`): A list of artefacts with their positions and sizes on the board. Defaults to an empty list.

### Methods
*(None explicitly defined)*

---

## Class: UpdateArtefactLayoutDTO

### Overview
`UpdateArtefactLayoutDTO` is used for updating the position, size, and name visibility of a specific artefact instance on a board.

### Properties
- `SavedArtefactId` (string, nullable): The ID of the specific saved artefact instance to update. If not provided, the API might try to match by `ArtefactId`.
- `ArtefactId` (string, required): The ID of the base artefact to update.
- `PosX` (float): The new X-position on the board.
- `PosY` (float): The new Y-position on the board.
- `Width` (float): The new width of the artefact.
- `Height` (float): The new height of the artefact.
- `NameVisible` (bool, nullable): Per-tile flag indicating if the artefact's name should be visible.

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(None apparent from the snippet, assuming `List` and `required` are C# built-ins)*

## Notable Packages
*(None beyond standard C# libraries)*
