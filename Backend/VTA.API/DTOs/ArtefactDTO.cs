namespace VTA.API.DTOs;

public partial class ArtefactPostDTO
{
    public ushort ArtefactIndex { get; set; }

    public required string UserId { get; set; }

    public string? CategoryId { get; set; }

    public required IFormFile Image { get; set; }
}

public partial class ArtefactGetDTO
{
    public string ArtefactId { get; set; } = null!;

    public ushort ArtefactIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? CategoryId { get; set; }

    public string? ImageUrl { get; set; }
}