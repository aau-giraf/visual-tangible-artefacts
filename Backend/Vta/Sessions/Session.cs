namespace Vta.Sessions;

public class Session
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaregiverId { get; set; }
    public Guid ChildId { get; set; }
    public SessionState State { get; set; } = SessionState.Pending;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? EndedAt { get; set; }
    public ICollection<SessionEvent> Events { get; set; } = new List<SessionEvent>();
}