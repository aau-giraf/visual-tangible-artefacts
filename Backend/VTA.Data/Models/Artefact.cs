namespace VTA.Data.Models;

public class Artefact
{
    public required string ArtefactId { get; set; }

    public required ushort ArtefactIndex { get; set; }

    public required int UserId { get; set; }

    public string? CategoryId { get; set; }

    public string? ImagePath { get; set; } = null!;
    public string? SoundPath { get; set; } = null!;
    public DateTime? ModifiedDate { get; set; }
    public string? Name { get; set; }
    public bool? NameShown { get; set; }
    public virtual Category? Category { get; set; }

    public virtual ICollection<SavedArtefact> SavedArtefacts { get; set; } = new List<SavedArtefact>();
}
