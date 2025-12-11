namespace VTA.API.DTOs;

/// <summary>
/// DTO for position and size information of an artefact on a board
/// </summary>
public class BoardArtefactLayoutDTO
{
    /// <summary>
    /// The ID of the artefact
    /// </summary>
    /// <summary>
    /// The ID of the saved artefact instance (nullable when creating a board)
    /// </summary>
    public string? SavedArtefactId { get; set; }

    public required string ArtefactId { get; set; }

    /// <summary>
    /// X position on the board
    /// </summary>
    public float PosX { get; set; }

    /// <summary>
    /// Y position on the board  
    /// </summary>
    public float PosY { get; set; }

    /// <summary>
    /// Width of the artefact
    /// </summary>
    public float Width { get; set; }

    /// <summary>
    /// Height of the artefact
    /// </summary>
    public float Height { get; set; } = 200;

    /// <summary>
    /// Per-tile flag indicating if the artefact's name should be visible.
    /// Mirrors the Flutter field `nameVisible`.
    /// </summary>
    public bool? NameVisible { get; set; }
    public float Height { get; set; }
}

/// <summary>
/// DTO for creating or updating a saved board
/// </summary>
public class SaveBoardRequestDTO
{
    /// <summary>
    /// Name of the board
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// List of artefacts with their positions and sizes
    /// </summary>
    public List<BoardArtefactLayoutDTO> Artefacts { get; set; } = new();
}

/// <summary>
/// DTO for board layout response
/// </summary>
public class BoardLayoutResponseDTO
{
    /// <summary>
    /// Board ID
    /// </summary>
    public required string BoardId { get; set; }

    /// <summary>
    /// Board name
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Date when board was created
    /// </summary>
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// Date when board was last modified
    /// </summary>
    public DateTime? ModifiedDate { get; set; }

    /// <summary>
    /// List of artefacts with their positions and sizes
    /// </summary>
    public List<BoardArtefactLayoutDTO> Artefacts { get; set; } = new();
}

/// <summary>
/// DTO for updating artefact position and size on a board
/// </summary>
public class UpdateArtefactLayoutDTO
{
    /// <summary>
    /// The ID of the artefact to update
    /// </summary>
    /// <summary>
    /// Optional saved artefact instance id. If provided, the update will target that specific instance.
    /// If not provided, the API will try to match by ArtefactId (may create a new instance when ambiguous).
    /// </summary>
    public string? SavedArtefactId { get; set; }

    /// <summary>
    /// The ID of the artefact to update
    /// </summary>
    public required string ArtefactId { get; set; }

    /// <summary>
    /// New X position on the board
    /// </summary>
    public float PosX { get; set; }

    /// <summary>
    /// New Y position on the board  
    /// </summary>
    public float PosY { get; set; }

    /// <summary>
    /// New width of the artefact
    /// </summary>
    public float Width { get; set; }

    /// <summary>
    /// New height of the artefact
    /// </summary>
    public float Height { get; set; }

    /// <summary>
    /// Per-tile flag indicating if the artefact's name should be visible (optional).
    /// Mirrors the Flutter field `nameVisible`.
    /// </summary>
    public bool? NameVisible { get; set; }
}