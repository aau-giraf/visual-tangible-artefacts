namespace SyncService.Services;

using System.Text.Json;

/// <summary>
/// Provides board sync relay helpers. Stateless.
/// </summary>
public class BoardSyncRelay : IBoardSyncRelay
{
    public string? ExtractSessionId(JsonElement data)
    {
        if (data.TryGetProperty("sessionId", out var sessionIdProp))
        {
            return sessionIdProp.GetString();
        }
        return null;
    }
}
