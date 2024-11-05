namespace VTA.API.Models;

public partial class Artefact
{
    public required string ArtefactId { get; set; }

    public required ushort ArtefactIndex { get; set; }

    public required string UserId { get; set; }

    public string? CategoryId { get; set; }

    public string? ImagePath { get; set; } = null!;
    public DateTime? ModifiedDate { get; set; }

    public virtual Category? Category { get; set; }

    public virtual User User { get; set; } = null!;
}
