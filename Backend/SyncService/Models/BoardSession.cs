namespace SyncService.Models;

//Used for creating a session for a board. 
public class BoardSession
{
    public required string SessionId { get; init; }
    public required string User1Id { get; init; }
    public required string User2Id { get; init; }
    public required string BoardId { get; init; }
    public HashSet<string> Connections { get; set; } = new();
}