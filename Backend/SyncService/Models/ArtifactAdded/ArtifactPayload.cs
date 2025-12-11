namespace SyncService.Models.ArtifactAdded;

public class ArtifactPayload
{
    public required string Id { get; set; }
    public required string SavedArtefactId { get; set; }
    public required string Name { get; set; }
    public string? ImageUrl { get; set; }
    public string? SoundUrl { get; set; }

    public required SizePayload Size { get; set; }

    public PositionPayload? Position { get; set; }
}