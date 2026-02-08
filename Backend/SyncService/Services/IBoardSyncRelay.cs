namespace SyncService.Services;

using System.Text.Json;

/// <summary>
/// Relays board and artifact delta events to session peers.
/// Provides a generic relay method and the validated ArtifactAdded flow.
/// Stateless — can be transient or singleton.
/// </summary>
public interface IBoardSyncRelay
{
    /// <summary>
    /// Extract sessionId from a JsonElement and return it, or null if missing.
    /// </summary>
    string? ExtractSessionId(JsonElement data);
}
