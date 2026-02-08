namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Tracks connected users, their SignalR connection IDs, and online status.
/// Registered as a singleton — state is shared across all hub invocations.
/// </summary>
public interface IPresenceService
{
    /// <summary>Register a user's connection and notify their contacts.</summary>
    void TrackConnection(string userId, string connectionId, List<string> contactIds, string userName);

    /// <summary>Remove a user's connection and return the userId that was removed (or null).</summary>
    string? RemoveConnection(string connectionId);

    /// <summary>Try to get the connection ID for a user.</summary>
    bool TryGetConnection(string userId, out string connectionId);

    /// <summary>Check if a connection ID is still registered to any user.</summary>
    bool IsConnectionActive(string connectionId);

    /// <summary>Get all currently online user IDs.</summary>
    List<string> GetOnlineUsers();

    /// <summary>Check if a specific user is online.</summary>
    bool IsUserOnline(string userId);

    /// <summary>Get the stored display name for a user.</summary>
    string GetUserName(string userId);

    /// <summary>Get the contact IDs registered for a user.</summary>
    List<string> GetContactIds(string userId);
}
