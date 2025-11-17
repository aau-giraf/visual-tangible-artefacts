namespace Vta.Sessions;

public class SessionEvent
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SessionId { get; set; }
    public SessionEventType Type { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public string? PayloadJson { get; set; }
    public Guid? TriggeredByUserId { get; set; }
    public Session? Session { get; set; }
}