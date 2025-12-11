namespace VTA.API.Models;

public class SavedArtefact
{
    public required string Id { get; set; }

    public required string ArtefactId { get; set; }

    public required string BoardId { get; set; }

    public float PosX { get; set; } = 0;

    public float PosY { get; set; } = 0;

    public float Width { get; set; } = 200;

    public float Height { get; set; } = 200;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public bool? NameVisible { get; set; }

    // Navigation properties
    public virtual Artefact Artefact { get; set; } = null!;

    public virtual SavedBoard Board { get; set; } = null!;
}
