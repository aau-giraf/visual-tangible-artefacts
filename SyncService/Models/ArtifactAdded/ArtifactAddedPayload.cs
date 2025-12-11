namespace SyncService.Models.ArtifactAdded;

public class ArtifactAddedPayload
{
    public required string SessionId { get; set; }
    public ArtifactPayload Artifact { get; set; }
}