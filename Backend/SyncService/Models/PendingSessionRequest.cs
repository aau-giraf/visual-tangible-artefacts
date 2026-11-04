namespace SyncService.Models;

//Used for dealing with pending sessions. 
public class PendingSessionRequest
{
    public required string FromUserId { get; set; }
    public required string ToUserId { get; set; }
    public required DateTime RequestTime { get; set; }
    public required CancellationTokenSource TimeoutCts { get; set; }
}