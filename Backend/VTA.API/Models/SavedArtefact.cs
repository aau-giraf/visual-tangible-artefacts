namespace VTA.API.Models;

public class SavedArtefact
{
    public required string Id { get; set; }

    public required string ArtefactId { get; set; }

    public required string BoardId { get; set; }

    public float PosX { get; set; } = 0;

    public float PosY { get; set; } = 0;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Artefact Artefact { get; set; } = null!;

    public virtual SavedBoard Board { get; set; } = null!;
}
