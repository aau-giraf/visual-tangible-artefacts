using VTA.Data.Models;

namespace VTA.API.DTOs
{
    public class SessionGetDTO
    {
        public int Id { get; set; }
        public string CallerId { get; set; } = string.Empty;
        public string CallerName { get; set; } = string.Empty;
        public string CalleeId { get; set; } = string.Empty;
        public string CalleeName { get; set; } = string.Empty;
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public TimeSpan? Duration { get; set; }
        public CallStatus CallStatus { get; set; }
    }

    public class SessionStatisticsDTO
    {
        public int TotalSessions { get; set; }
        public int CompletedSessions { get; set; }
        public int RejectedSessions { get; set; }
        public int FailedSessions { get; set; }
        public TimeSpan? AverageDuration { get; set; }
        public TimeSpan? TotalDuration { get; set; }
    }
}
