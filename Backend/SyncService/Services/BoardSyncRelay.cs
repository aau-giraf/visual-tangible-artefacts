namespace SyncService.Services;

using System.Text.Json;

/// <summary>
/// Provides board sync relay helpers. Stateless.
/// </summary>
public class BoardSyncRelay : IBoardSyncRelay // BoardSyncRelay implements the IBoardSyncRelay interface. 
{
    public string? ExtractSessionId(JsonElement data)
    {
        if (data.TryGetProperty("sessionId", out var sessionIdProp)) //Looks for sessionId in the json element. 
        {
            return sessionIdProp.GetString(); //Returns the sessionId as a string. 
        }
        return null;
    }
}
