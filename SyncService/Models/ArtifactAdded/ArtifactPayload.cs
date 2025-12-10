namespace SyncService.Models.ArtifactAdded;

public class ArtifactPayload
{
    public string Id { get; set; } = string.Empty;
    public string SavedArtefactId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; } = string.Empty;
    public string? SoundUrl { get; set; } = string.Empty;

    public SizePayload Size { get; set; } = null!;

    public PositionPayload? Position { get; set; }
}