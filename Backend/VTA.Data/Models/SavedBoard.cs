namespace VTA.Data.Models;

public class SavedBoard
{
    public required string Id { get; set; }

    public required string Name { get; set; }

    public required string UserId { get; set; }

    public string? SnapshotPath { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public DateTime? ModifiedDate { get; set; }

    // Navigation properties
    public virtual User User { get; set; } = null!;

    // JSON array containing SavedArtefact IDs present on this board (e.g. ["savedId1","savedId2",...])
    // This stores the actual SavedArtefact record IDs to handle multiple instances of the same artefact
    public string? SavedArtefactIds { get; set; }

    // JSON array containing artefact IDs present on this board (e.g. ["id1","id2",...])
    // This is used for quick lookup of which artefacts exist on the board without joining
    // to the savedArtefact table. It is nullable and kept in sync by the controller.
    public string? ArtefactIds { get; set; }

    public virtual ICollection<SavedArtefact> SavedArtefacts { get; set; } = new List<SavedArtefact>();
}
