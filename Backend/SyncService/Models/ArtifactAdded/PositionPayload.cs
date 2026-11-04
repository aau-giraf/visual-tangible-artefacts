namespace SyncService.Models.ArtifactAdded;

//Used for the position of the artifact. 
//Takes a x and y coordinate where both are decimals. 
public class PositionPayload
{
    public required decimal Dx { get; set; }
    public required decimal Dy { get; set; }
}