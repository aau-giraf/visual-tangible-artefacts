namespace SyncService.Models.ArtifactAdded;

//Used for the size of the artifact. 
//Takes a width and height where both are decimals. 
public class SizePayload
{
    public required decimal Width { get; set; }
    public required decimal Height { get; set; }
}