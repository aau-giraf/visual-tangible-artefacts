namespace Vta.Contracts;

public record StartSessionRequest(Guid CaregiverId, Guid ChildId);
public record SessionRequestNotification(Guid SessionId, Guid CaregiverId);
public record SessionDecision(Guid SessionId);
public record BoardUpdateDto(Guid SessionId, string ChangeType, string PayloadJson, DateTimeOffset OccurredAt);
public record SessionSummary(Guid SessionId, Vta.Sessions.SessionState State, Guid CaregiverId, Guid ChildId);
