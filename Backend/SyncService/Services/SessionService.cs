namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Manages session lifecycle: pending requests and active board sessions.
/// Singleton — shared state across all hub invocations.
/// </summary>
public class SessionService : ISessionService
{
    private readonly Dictionary<string, BoardSession> _sessions = new(); //Makes a new instrance of sessions. 
    private readonly Dictionary<string, PendingSessionRequest> _pendingRequests = new(); //Makes a new instrance of pendingRequests. 

    public string CreatePendingRequest(string fromUserId, string toUserId) //New session request pending. 
    {
        var requestKey = $"{fromUserId}_{toUserId}_{DateTime.UtcNow.Ticks}"; //Variable requestKey is a string consisting of fromUserId, toUserID and the time. 
        var cts = new CancellationTokenSource(); // Variable cts is a new instrance of the CancellationTokenSource. 

    //pendingRequests takes the variable requestKey and makes a new instance of PendingSessionRequest. 
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
        //The variable keysToRemove is a list of keys. 
        //The keys are input sequences that has been filtered. 
        var keysToRemove = _pendingRequests
            .Where(x => x.Value.FromUserId == fromUserId &&
                        (toUserId == null || x.Value.ToUserId == toUserId))
            .Select(x => x.Key)
            .ToList();

        //Checks all keys in keysToRemove. 
        //If the pending request has the specified key, the request will be cancelled and removed. 
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
