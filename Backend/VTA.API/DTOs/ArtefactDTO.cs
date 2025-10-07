namespace VTA.API.DTOs;

/// <summary>
/// DTO for creating a new artefact
/// </summary>
public partial class ArtefactPostDTO
{
    /// <summary>
    /// The index of the artefact
    /// </summary>
    public ushort ArtefactIndex { get; set; }

    /// <summary>
    /// The ID of the user who owns the artefact
    /// </summary>
    public required string UserId { get; set; }

    /// <summary>
    /// The category ID the artefact belongs to
    /// </summary>
    public string? CategoryId { get; set; }
    
    /// <summary>
    /// The name of the artefact
    /// </summary>
    public string? Name {get; set; }
    
    /// <summary>
    /// The image file for the artefact
    /// </summary>
    public required IFormFile Image { get; set; }
    
    /// <summary>
    /// The sound file for the artefact
    /// </summary>
    public IFormFile? Sound { get; set; }
}

/// <summary>
/// DTO for updating an existing artefact
/// </summary>
public partial class ArtefactPatchDTO
{
    /// <summary>
    /// The ID of the artefact to update
    /// </summary>
    public required string ArtefactId { get; set; }

    /// <summary>
    /// The index of the artefact
    /// </summary>
    public ushort? ArtefactIndex { get; set; }

    /// <summary>
    /// The ID of the user who owns the artefact
    /// </summary>
    public required string UserId { get; set; }

    /// <summary>
    /// The category ID the artefact belongs to
    /// </summary>
    public string? CategoryId { get; set; }

    /// <summary>
    /// The name of the artefact
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// The image file for the artefact
    /// </summary>
    public IFormFile? Image { get; set; }
    
    /// <summary>
    /// The sound file for the artefact
    /// </summary>
    public IFormFile? Sound { get; set; }

}

/// <summary>
/// DTO for returning artefact data
/// </summary>
public partial class ArtefactGetDTO
{
    /// <summary>
    /// The unique identifier of the artefact
    /// </summary>
    public string ArtefactId { get; set; } = null!;

    /// <summary>
    /// The index of the artefact
    /// </summary>
    public ushort ArtefactIndex { get; set; }

    /// <summary>
    /// The ID of the user who owns the artefact
    /// </summary>
    public string UserId { get; set; } = null!;

    /// <summary>
    /// The category ID the artefact belongs to
    /// </summary>
    public string? CategoryId { get; set; }
    
    /// <summary>
    /// The name of the artefact
    /// </summary>
    public string? Name {get; set; }

    /// <summary>
    /// The URL to the artefact's image
    /// </summary>
    public string? ImageUrl { get; set; }
    
    /// <summary>
    /// The URL to the artefact's sound
    /// </summary>
    public string? SoundUrl { get; set; }
}

/// <summary>
/// DTO for generating text-to-speech for an artefact
/// </summary>
public partial class ArtefactTextToSpeechDTO
{
    /// <summary>
    /// The ID of the artefact to generate speech for
    /// </summary>
    public required string ArtefactId { get; set; }
    
    /// <summary>
    /// The text to convert to speech
    /// </summary>
    public required string Text { get; set; }
    
    /// <summary>
    /// The ElevenLabs voice ID to use (optional)
    /// </summary>
    public string? VoiceId { get; set; }
    
    /// <summary>
    /// The ElevenLabs model ID to use (optional)
    /// </summary>
    public string? ModelId { get; set; }
    
    /// <summary>
    /// Voice stability setting (0.0 to 1.0)
    /// </summary>
    public double? Stability { get; set; }
    
    /// <summary>
    /// Voice similarity boost setting (0.0 to 1.0)
    /// </summary>
    public double? SimilarityBoost { get; set; }
    
    /// <summary>
    /// Whether to use speaker boost
    /// </summary>
    public bool? UseSpeakerBoost { get; set; }
}