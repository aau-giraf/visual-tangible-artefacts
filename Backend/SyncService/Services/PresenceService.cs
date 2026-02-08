namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Tracks connected users, their SignalR connection IDs, and online status.
/// Singleton — shared state across all hub invocations.
/// </summary>
public class PresenceService : IPresenceService
{
    private readonly Dictionary<string, string> _userConnections = new();
    private readonly HashSet<string> _onlineUsers = new();
    private readonly Dictionary<string, List<string>> _userContactsMap = new();
    private readonly Dictionary<string, UserInfo> _userInfoMap = new();

    public void TrackConnection(string userId, string connectionId, List<string> contactIds, string userName)
    {
        _userConnections[userId] = connectionId;
        _onlineUsers.Add(userId);
        _userContactsMap[userId] = contactIds ?? new List<string>();
        _userInfoMap[userId] = new UserInfo { UserId = userId, Name = userName };
    }

    public string? RemoveConnection(string connectionId)
    {
        var userId = _userConnections.FirstOrDefault(x => x.Value == connectionId).Key;
        if (userId == null) return null;

        _userConnections.Remove(userId);
        _onlineUsers.Remove(userId);
        _userContactsMap.Remove(userId);
        _userInfoMap.Remove(userId);
        return userId;
    }

    public bool TryGetConnection(string userId, out string connectionId)
    {
        return _userConnections.TryGetValue(userId, out connectionId!);
    }

    public bool IsConnectionActive(string connectionId)
    {
        return _userConnections.ContainsValue(connectionId);
    }

    public List<string> GetOnlineUsers()
    {
        return _onlineUsers.ToList();
    }

    public bool IsUserOnline(string userId)
    {
        return _onlineUsers.Contains(userId);
    }

    public string GetUserName(string userId)
    {
        return _userInfoMap.TryGetValue(userId, out var info) ? info.Name : "User";
    }

    public List<string> GetContactIds(string userId)
    {
        return _userContactsMap.TryGetValue(userId, out var contacts) ? contacts : new List<string>();
    }
}
