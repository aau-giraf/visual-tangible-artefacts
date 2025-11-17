using Vta.Pairings;
using Vta.Sessions;

namespace Vta.Application.Sessions;

public class SessionService : ISessionService
{
    private readonly IRepository<Session> _sessions;
    private readonly IRepository<CaregiverChildPairing> _pairings;

    public SessionService(IRepository<Session> sessions, IRepository<CaregiverChildPairing> pairings)
    {
        _sessions = sessions;
        _pairings = pairings;
    }

    public async Task<Session> StartSessionAsync(Guid caregiverId, Guid childId, CancellationToken ct)
    {
        var pairing = await _pairings.FirstOrDefaultAsync(
            p => p.CaregiverId == caregiverId && p.ChildId == childId && p.IsActive, ct)
            ?? throw new InvalidOperationException("Caregiver not paired with child.");

        var active = await _sessions.AnyAsync(
            s => s.ChildId == childId && s.State is SessionState.Pending or SessionState.Active, ct);
        if (active) throw new InvalidOperationException("Child already in session.");

        var session = new Session { CaregiverId = caregiverId, ChildId = childId };
        session.Events.Add(new SessionEvent
        {
            SessionId = session.Id,
            Type = SessionEventType.RequestSent,
            TriggeredByUserId = caregiverId
        });
        await _sessions.AddAsync(session, ct);
        return session;
    }

    public async Task<Session> AcceptAsync(Guid sessionId, Guid actingChildId, CancellationToken ct)
    {
        var session = await RequireSession(sessionId, ct);
        EnsureChild(session, actingChildId);
        EnsureState(session, SessionState.Pending);

        session.State = SessionState.Active;
        session.StartedAt = DateTimeOffset.UtcNow;
        session.Events.Add(new SessionEvent
        {
            SessionId = session.Id,
            Type = SessionEventType.Accepted,
            TriggeredByUserId = actingChildId
        });
        await _sessions.UpdateAsync(session, ct);
        return session;
    }

    public async Task<Session> DenyAsync(Guid sessionId, Guid actingChildId, CancellationToken ct)
    {
        var session = await RequireSession(sessionId, ct);
        EnsureChild(session, actingChildId);
        EnsureState(session, SessionState.Pending);

        session.State = SessionState.Denied;
        session.EndedAt = DateTimeOffset.UtcNow;
        session.Events.Add(new SessionEvent
        {
            SessionId = session.Id,
            Type = SessionEventType.Denied,
            TriggeredByUserId = actingChildId
        });
        await _sessions.UpdateAsync(session, ct);
        return session;
    }

    public async Task<Session> EndAsync(Guid sessionId, Guid actingUserId, CancellationToken ct)
    {
        var session = await RequireSession(sessionId, ct);
        if (session.State is SessionState.Ended or SessionState.Denied or SessionState.Expired) return session;

        session.State = SessionState.Ended;
        session.EndedAt = DateTimeOffset.UtcNow;
        session.Events.Add(new SessionEvent
        {
            SessionId = session.Id,
            Type = actingUserId == session.ChildId ? SessionEventType.EndedByChild : SessionEventType.EndedByCaregiver,
            TriggeredByUserId = actingUserId
        });
        await _sessions.UpdateAsync(session, ct);
        return session;
    }

    public Task<Session?> GetAsync(Guid sessionId, CancellationToken ct) =>
        _sessions.FirstOrDefaultAsync(s => s.Id == sessionId, ct);

    private static void EnsureChild(Session s, Guid childId)
    {
        if (s.ChildId != childId) throw new InvalidOperationException("Only the child can perform this action.");
    }

    private static void EnsureState(Session s, SessionState expected)
    {
        if (s.State != expected) throw new InvalidOperationException($"Session must be {expected}.");
    }

    private async Task<Session> RequireSession(Guid id, CancellationToken ct) =>
        await _sessions.FirstOrDefaultAsync(s => s.Id == id, ct) ?? throw new KeyNotFoundException("Session not found.");
}