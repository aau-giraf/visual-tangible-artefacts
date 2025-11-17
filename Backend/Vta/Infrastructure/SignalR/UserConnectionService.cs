using System.Collections.Concurrent;

namespace Vta.SignalR;

public interface IUserConnectionService
{
    void Add(string userId, string connectionId);
    void Remove(string userId, string connectionId);
    IReadOnlyCollection<string> GetConnections(string userId);
}

public class InMemoryUserConnectionService : IUserConnectionService
{
    private readonly ConcurrentDictionary<string, HashSet<string>> _map = new();

    public void Add(string userId, string connectionId)
    {
        var set = _map.GetOrAdd(userId, _ => new HashSet<string>());
        lock (set) set.Add(connectionId);
    }

    public void Remove(string userId, string connectionId)
    {
        if (_map.TryGetValue(userId, out var set))
        {
            lock (set) set.Remove(connectionId);
            if (set.Count == 0) _map.TryRemove(userId, out _);
        }
    }

    public IReadOnlyCollection<string> GetConnections(string userId) =>
        _map.TryGetValue(userId, out var set) ? set.ToArray() : Array.Empty<string>();
}