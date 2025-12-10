namespace SyncService.Models.ArtifactAdded;

public class ArtifactAddedPayload
{
    public string SessionId { get; set; } = string.Empty;
    public ArtifactPayload Artifact { get; set; }
}