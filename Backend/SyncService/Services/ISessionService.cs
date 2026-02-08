namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Manages session lifecycle: request, accept, reject, end, and timeout.
/// Registered as a singleton — pending requests and active sessions are shared state.
/// DB operations require a VTAContext passed from the Hub (scoped).
/// </summary>
public interface ISessionService
{
    /// <summary>Store a pending session request and return its key.</summary>
    string CreatePendingRequest(string fromUserId, string toUserId);

    /// <summary>Cancel and remove all pending requests matching fromUserId→toUserId.</summary>
    void CancelPendingRequests(string fromUserId, string? toUserId = null);

    /// <summary>Check if a pending request still exists by key.</summary>
    bool IsPending(string requestKey);

    /// <summary>Remove a pending request by key.</summary>
    void RemovePendingRequest(string requestKey);

    /// <summary>Store an active board session.</summary>
    void AddSession(BoardSession session);

    /// <summary>Try to get an active session by ID.</summary>
    bool TryGetSession(string sessionId, out BoardSession session);

    /// <summary>Remove an active session by ID.</summary>
    void RemoveSession(string sessionId);

    /// <summary>Get all sessions involving a given user.</summary>
    List<KeyValuePair<string, BoardSession>> GetSessionsForUser(string userId);
}
