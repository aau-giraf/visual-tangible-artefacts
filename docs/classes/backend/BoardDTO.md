# Classes: BoardPostDTO, BoardPatchDTO, BoardGetDTO, BoardListItemDTO, SavedArtefactPostDTO, SavedArtefactPatchDTO, SavedArtefactGetDTO

**Path:** `Backend/VTA.API/DTOs/BoardDTO.cs`

## Overview
This file defines various Data Transfer Objects (DTOs) used for handling board-related operations, including creating, updating, and retrieving boards, as well as managing artefacts placed on these boards (SavedArtefacts).

---

## Class: BoardPostDTO

### Overview
`BoardPostDTO` is used for creating a new board, requiring a name and optionally a snapshot path.

### Properties
- `Name` (string, required): The name of the board.
- `SnapshotPath` (string, nullable): Optional path to a snapshot/thumbnail image of the board.

### Methods
*(None explicitly defined)*

---

## Class: BoardPatchDTO

### Overview
`BoardPatchDTO` is used for updating an existing board's properties, identified by its `BoardId`.

### Properties
- `BoardId` (string, required): The ID of the board to update.
- `Name` (string, nullable): The new name of the board.
- `SnapshotPath` (string, nullable): The new path to a snapshot/thumbnail image of the board.

### Methods
*(None explicitly defined)*

---

## Class: BoardGetDTO

### Overview
`BoardGetDTO` is used for returning comprehensive data about a board, including its metadata and a collection of associated `SavedArtefactGetDTO`s. It includes backwards-compatible properties for frontend clients.

### Properties
- `Id` (string): The unique identifier of the board.
- `Name` (string): The name of the board.
- `UserId` (string): The ID of the user who owns the board.
- `SnapshotUrl` (string, nullable): URL to the snapshot/thumbnail image of the board. (`JsonPropertyName("snapshotUrl")`)
- `CreatedDate` (DateTime): When the board was created. (`JsonPropertyName("createdDate")`)
- `ModifiedDate` (DateTime, nullable): When the board was last modified. (`JsonPropertyName("modifiedDate")`)
- `SavedArtefacts` (`ICollection<SavedArtefactGetDTO>`): Collection of artefacts placed on this board.
- `Artefacts` (`IEnumerable<SavedArtefactGetDTO>`): Backwards-compatible property, serializes the same collection as `SavedArtefacts`. (`JsonPropertyName("artefacts")`)
- `BoardId` (string): Backwards-compatible property, serializes the same value as `Id`. (`JsonPropertyName("boardId")`)

### Methods
*(None explicitly defined)*

---

## Class: BoardListItemDTO

### Overview
`BoardListItemDTO` is a minimal DTO for returning essential board information (ID, name, thumbnail, dates) for list views. It includes a backwards-compatible property for frontend clients.

### Properties
- `Id` (string): The unique identifier of the board.
- `Name` (string): The name of the board.
- `SnapshotUrl` (string, nullable): URL to the snapshot/thumbnail image of the board. (`JsonPropertyName("snapshotUrl")`)
- `CreatedDate` (DateTime): When the board was created. (`JsonPropertyName("createdDate")`)
- `ModifiedDate` (DateTime, nullable): When the board was last modified. (`JsonPropertyName("modifiedDate")`)
- `BoardId` (string): Backwards-compatible property, serializes the same value as `Id`. (`JsonPropertyName("boardId")`)

### Methods
*(None explicitly defined)*

---

## Class: SavedArtefactPostDTO

### Overview
`SavedArtefactPostDTO` is used for placing a new artefact on a board, specifying its ID and initial position.

### Properties
- `ArtefactId` (string, required): The ID of the artefact to place on the board.
- `PosX` (float): X position on the board. Defaults to `0`.
- `PosY` (float): Y position on the board. Defaults to `0`.

### Methods
*(None explicitly defined)*

---

## Class: SavedArtefactPatchDTO

### Overview
`SavedArtefactPatchDTO` is used for updating the position of an existing saved artefact instance on a board.

### Properties
- `SavedArtefactId` (string, required): The ID of the saved artefact to update.
- `PosX` (float, nullable): The new X position on the board.
- `PosY` (float, nullable): The new Y position on the board.

### Methods
*(None explicitly defined)*

---

## Class: SavedArtefactGetDTO

### Overview
`SavedArtefactGetDTO` is used for returning detailed information about an artefact placed on a board, including its position, size, and reference to the original artefact data. It includes a backwards-compatible property.

### Properties
- `Id` (string): The unique identifier of this saved artefact instance.
- `ArtefactId` (string): The ID of the base artefact (template). (`JsonPropertyName("artefactId")`)
- `BoardId` (string): The ID of the board this artefact is placed on. (`JsonPropertyName("boardId")`)
- `PosX` (float): X position on the board. (`JsonPropertyName("posX")`)
- `PosY` (float): Y position on the board. (`JsonPropertyName("posY")`)
- `Width` (float): Width of the artefact on the board. (`JsonPropertyName("width")`)
- `Height` (float): Height of the artefact on the board. (`JsonPropertyName("height")`)
- `CreatedDate` (DateTime): When this artefact was placed on the board. (`JsonPropertyName("createdDate")`)
- `Artefact` (`ArtefactGetDTO`): The artefact data (template information). (`JsonPropertyName("artefact")`)
- `SavedArtefactId` (string): Backwards-compatible property, serializes the same value as `Id`. (`JsonPropertyName("savedArtefactId")`)

### Methods
*(None explicitly defined)*

---

## Internal Imports
*(Implicitly, `ArtefactGetDTO` and `SavedArtefactGetDTO` are from the same namespace `VTA.API.DTOs`.)*

## Notable Packages
- `System.Text.Json.Serialization` (for `JsonPropertyName` attribute)
