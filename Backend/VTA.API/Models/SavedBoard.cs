namespace VTA.API.Models;

public class SavedBoard
{
    public required string Id { get; set; }

    public required string Name { get; set; }

    public required string UserId { get; set; }

    public string? SavedArtefactId { get; set; }

    public string? SnapshotPath { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public DateTime? ModifiedDate { get; set; }

    // Navigation properties
    public virtual User User { get; set; } = null!;

    public virtual SavedArtefact? SavedArtefact { get; set; }

    public virtual ICollection<SavedArtefact> SavedArtefacts { get; set; } = new List<SavedArtefact>();
}
