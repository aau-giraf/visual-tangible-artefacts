namespace VTA.Data.Models;

//Entity Framework Core entity model that represents a call session stored in the application's database.
public class Session
{
    public int Id { get; set; }
    public required string CallerId { get; set; }
    public required string CalleeId { get; set; }
    public DateTime? StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public TimeSpan? Duration { get; set; }
    public CallStatus CallStatus { get; set; }
    public virtual User Caller { get; set; } = null!;
    public virtual User Callee { get; set; } = null!;
}
