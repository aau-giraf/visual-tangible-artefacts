namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Manages session lifecycle: pending requests and active board sessions.
/// Singleton — shared state across all hub invocations.
/// </summary>
public class SessionService : ISessionService
{
    private readonly Dictionary<string, BoardSession> _sessions = new();
    private readonly Dictionary<string, PendingSessionRequest> _pendingRequests = new();

    public string CreatePendingRequest(string fromUserId, string toUserId)
    {
        var requestKey = $"{fromUserId}_{toUserId}_{DateTime.UtcNow.Ticks}";
        var cts = new CancellationTokenSource();

        _pendingRequests[requestKey] = new PendingSessionRequest
        {
            FromUserId = fromUserId,
            ToUserId = toUserId,
            RequestTime = DateTime.UtcNow,
            TimeoutCts = cts
        };

        return requestKey;
    }

    public void CancelPendingRequests(string fromUserId, string? toUserId = null)
    {
        var keysToRemove = _pendingRequests
            .Where(x => x.Value.FromUserId == fromUserId &&
                        (toUserId == null || x.Value.ToUserId == toUserId))
            .Select(x => x.Key)
            .ToList();

        foreach (var key in keysToRemove)
        {
            if (_pendingRequests.TryGetValue(key, out var request))
            {
                request.TimeoutCts.Cancel();
                _pendingRequests.Remove(key);
            }
        }
    }

    public bool IsPending(string requestKey)
    {
        return _pendingRequests.ContainsKey(requestKey);
    }

    public void RemovePendingRequest(string requestKey)
    {
        _pendingRequests.Remove(requestKey);
    }

    public void AddSession(BoardSession session)
    {
        _sessions[session.SessionId] = session;
    }

    public bool TryGetSession(string sessionId, out BoardSession session)
    {
        return _sessions.TryGetValue(sessionId, out session!);
    }

    public void RemoveSession(string sessionId)
    {
        _sessions.Remove(sessionId);
    }

    public List<KeyValuePair<string, BoardSession>> GetSessionsForUser(string userId)
    {
        return _sessions
            .Where(s => s.Value.User1Id == userId || s.Value.User2Id == userId)
            .ToList();
    }
}
