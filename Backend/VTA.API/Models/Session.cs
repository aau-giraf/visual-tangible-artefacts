namespace VTA.API.Models;

public enum SessionState
{
    Pending = 0,
    Active = 1,
    Ended = 2,
    Denied = 3
}

public class Session
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public required string CaregiverId { get; set; }
    public required string ChildId { get; set; }
    public SessionState State { get; set; } = SessionState.Pending;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? EndedAt { get; set; }

    public virtual User Caregiver { get; set; } = null!;
    public virtual User Child { get; set; } = null!;
    public virtual ICollection<SessionEvent> Events { get; set; } = new List<SessionEvent>();
}

public enum SessionEventType
{
    Created = 0,
    Started = 1,
    Ended = 2,
    Accepted = 3,
    Denied = 4
}

public class SessionEvent
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public required string SessionId { get; set; }
    public SessionEventType EventType { get; set; }
    public DateTimeOffset Timestamp { get; set; } = DateTimeOffset.UtcNow;
    public string? Data { get; set; }

    public virtual Session Session { get; set; } = null!;
}