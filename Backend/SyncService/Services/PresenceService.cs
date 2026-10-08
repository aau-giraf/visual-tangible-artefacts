namespace SyncService.Services;

using SyncService.Models;

/// <summary>
/// Tracks connected users, their SignalR connection IDs, and online status.
/// Singleton — shared state across all hub invocations.
/// </summary>
public class PresenceService : IPresenceService // PresenceService implements the IPresenceService interface. 
{   
    // private: can only be accessed and changed in the class. readonly: cannot be modified after creation. 
    private readonly Dictionary<string, string> _userConnections = new(); // Makes a new instrance of userConnections. userConnections is a set of key/value pairs. 
    private readonly HashSet<string> _onlineUsers = new(); // Makes a new instrance of onlineUsers. onlineUsers is a set od values. 
    private readonly Dictionary<string, List<string>> _userContactsMap = new(); // Makes a new instrance of userContactsMap.  
    private readonly Dictionary<string, UserInfo> _userInfoMap = new(); // Makes a new instrance of UserInfoMap.  

    public void TrackConnection(string userId, string connectionId, List<string> contactIds, string userName) // TrackConnection 
    {
        _userConnections[userId] = connectionId; // Given userId(key) userConncetions returns a connectionId(value). 
        _onlineUsers.Add(userId); // Adds an userId to the set of onlineUsers, if the Id is not already present. 
        _userContactsMap[userId] = contactIds ?? new List<string>(); // Given userId(key) userContactsMap creates a new instrance of a list of contactIds(value). 
        _userInfoMap[userId] = new UserInfo { UserId = userId, Name = userName }; // Given userId(key) userInfoMaps creats a new UserInfo, which needs a userId and a 
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
