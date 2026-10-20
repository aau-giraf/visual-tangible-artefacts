namespace SyncService.Models.ArtifactAdded;

//Used to add an artifact to a session. 
//Takes a string called SessionId and an ArtifactPayload called artifact.
public class ArtifactAddedPayload
{
    public required string SessionId { get; set; }
    public required ArtifactPayload Artifact { get; set; }
}