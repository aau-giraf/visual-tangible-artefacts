using Vta.Pairings;
using Vta.Sessions;

namespace Vta.Application.Sessions;

public interface ISessionService
{
    Task<Session> StartSessionAsync(Guid caregiverId, Guid childId, CancellationToken ct);
    Task<Session> AcceptAsync(Guid sessionId, Guid actingChildId, CancellationToken ct);
    Task<Session> DenyAsync(Guid sessionId, Guid actingChildId, CancellationToken ct);
    Task<Session> EndAsync(Guid sessionId, Guid actingUserId, CancellationToken ct);
    Task<Session?> GetAsync(Guid sessionId, CancellationToken ct);
}
