using System.Text.Json.Serialization;
using System.Collections.Generic;
using System.Linq;

namespace VTA.API.DTOs;

/// <summary>
/// DTO for creating a new board
/// </summary>
public partial class BoardPostDTO
{
    /// <summary>
    /// The name of the board
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Optional path to a snapshot/thumbnail image of the board
    /// </summary>
    public string? SnapshotPath { get; set; }
}

/// <summary>
/// DTO for updating an existing board
/// </summary>
public partial class BoardPatchDTO
{
    /// <summary>
    /// The ID of the board to update
    /// </summary>
    public required string BoardId { get; set; }

    /// <summary>
    /// The name of the board
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// Path to a snapshot/thumbnail image of the board
    /// </summary>
    public string? SnapshotPath { get; set; }
}

/// <summary>
/// DTO for returning full board data with all saved artefacts
/// </summary>
public partial class BoardGetDTO
{
    /// <summary>
    /// The unique identifier of the board
    /// </summary>
    public string Id { get; set; } = null!;

    /// <summary>
    /// The name of the board
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// The ID of the user who owns the board
    /// </summary>
    public string UserId { get; set; } = null!;

    /// <summary>
    /// URL to the snapshot/thumbnail image of the board
    /// </summary>
    [JsonPropertyName("snapshotUrl")]
    public string? SnapshotUrl { get; set; }

    /// <summary>
    /// When the board was created
    /// </summary>
    [JsonPropertyName("createdDate")]
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// When the board was last modified
    /// </summary>
    [JsonPropertyName("modifiedDate")]
    public DateTime? ModifiedDate { get; set; }

    /// <summary>
    /// Collection of artefacts placed on this board
    /// </summary>
    public virtual ICollection<SavedArtefactGetDTO> SavedArtefacts { get; set; } = new List<SavedArtefactGetDTO>();

    /// <summary>
    /// Backwards-compatible property name for the frontend which expects `artefacts`.
    /// Serializes the same collection as <see cref="SavedArtefacts"/> under the name `artefacts`.
    /// </summary>
    [JsonPropertyName("artefacts")]
    public IEnumerable<SavedArtefactGetDTO> Artefacts => SavedArtefacts ?? Enumerable.Empty<SavedArtefactGetDTO>();

    /// <summary>
    /// Backwards-compatible property name expected by the frontend clients.
    /// Serializes the same value as <see cref="Id"/> under the name `boardId`.
    /// </summary>
    [JsonPropertyName("boardId")]
    public string BoardId => Id;
}

/// <summary>
/// DTO for returning a minimal board list item (ID, name, and thumbnail)
/// </summary>
public partial class BoardListItemDTO
{
    /// <summary>
    /// The unique identifier of the board
    /// </summary>
    public string Id { get; set; } = null!;

    /// <summary>
    /// The name of the board
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// URL to the snapshot/thumbnail image of the board
    /// </summary>
    [JsonPropertyName("snapshotUrl")]
    public string? SnapshotUrl { get; set; }

    /// <summary>
    /// When the board was created
    /// </summary>
    [JsonPropertyName("createdDate")]
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// When the board was last modified
    /// </summary>
    [JsonPropertyName("modifiedDate")]
    public DateTime? ModifiedDate { get; set; }

    /// <summary>
    /// Backwards-compatible property name expected by the frontend clients.
    /// Serializes the same value as <see cref="Id"/> under the name `boardId`.
    /// </summary>
    [JsonPropertyName("boardId")]
    public string BoardId => Id;
}

/// <summary>
/// DTO for creating a saved artefact (placing an artefact on a board)
/// </summary>
public partial class SavedArtefactPostDTO
{
    /// <summary>
    /// The ID of the artefact to place on the board
    /// </summary>
    public required string ArtefactId { get; set; }

    /// <summary>
    /// X position on the board
    /// </summary>
    public float PosX { get; set; } = 0;

    /// <summary>
    /// Y position on the board
    /// </summary>
    public float PosY { get; set; } = 0;
}

/// <summary>
/// DTO for updating a saved artefact's position
/// </summary>
public partial class SavedArtefactPatchDTO
{
    /// <summary>
    /// The ID of the saved artefact to update
    /// </summary>
    public required string SavedArtefactId { get; set; }

    /// <summary>
    /// X position on the board
    /// </summary>
    public float? PosX { get; set; }

    /// <summary>
    /// Y position on the board
    /// </summary>
    public float? PosY { get; set; }
}

/// <summary>
/// DTO for returning saved artefact data
/// </summary>
public partial class SavedArtefactGetDTO
{
    /// <summary>
    /// The unique identifier of this saved artefact instance
    /// </summary>
    public string Id { get; set; } = null!;

    /// <summary>
    /// The ID of the artefact (template)
    /// </summary>
    [JsonPropertyName("artefactId")]
    public string ArtefactId { get; set; } = null!;

    /// <summary>
    /// The ID of the board this artefact is placed on
    /// </summary>
    [JsonPropertyName("boardId")]
    public string BoardId { get; set; } = null!;

    /// <summary>
    /// X position on the board
    /// </summary>
    [JsonPropertyName("posX")]
    public float PosX { get; set; }

    /// <summary>
    /// Y position on the board
    /// </summary>
    [JsonPropertyName("posY")]
    public float PosY { get; set; }

    /// <summary>
    /// Width of the artefact on the board
    /// </summary>
    [JsonPropertyName("width")]
    public float Width { get; set; }

    /// <summary>
    /// Height of the artefact on the board
    /// </summary>
    [JsonPropertyName("height")]
    public float Height { get; set; }

    /// <summary>
    /// When this artefact was placed on the board
    /// </summary>
    [JsonPropertyName("createdDate")]
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// The artefact data (template information)
    /// </summary>
    [JsonPropertyName("artefact")]
    public ArtefactGetDTO Artefact { get; set; } = null!;

    /// <summary>
    /// Backwards-compatible property name for saved artefact instance id expected by the frontend.
    /// Serializes the same value as <see cref="Id"/> under the name `savedArtefactId`.
    /// </summary>
    [JsonPropertyName("savedArtefactId")]
    public string SavedArtefactId => Id;
}