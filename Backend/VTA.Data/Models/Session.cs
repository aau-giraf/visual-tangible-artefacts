namespace VTA.Data.Models;

public class Session
{
    public int Id { get; set; }
    public required int CallerId { get; set; }
    public required int CalleeId { get; set; }
    public DateTime? StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public TimeSpan? Duration { get; set; }
    public CallStatus CallStatus { get; set; }
}
