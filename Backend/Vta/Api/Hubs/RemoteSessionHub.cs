using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Vta.Application.Sessions;
using Vta.Contracts;
using Vta.SignalR;
using Vta.Sessions;

namespace Vta.Api.Hubs;

[Authorize]
public class RemoteSessionHub : Hub
{
    private readonly ISessionService _sessionService;
    private readonly IUserConnectionService _connService;

    public RemoteSessionHub(ISessionService sessionService, IUserConnectionService connService)
    {
        _sessionService = sessionService;
        _connService = connService;
    }

    public override Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier ?? throw new InvalidOperationException("Missing user id.");
        _connService.Add(userId, Context.ConnectionId);
        return base.OnConnectedAsync();
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier;
        if (userId != null) _connService.Remove(userId, Context.ConnectionId);
        return base.OnDisconnectedAsync(exception);
    }

    [Authorize(Roles = "Caregiver")]
    public async Task<SessionSummary> StartSession(Guid childId, CancellationToken ct)
    {
        var caregiverId = Guid.Parse(Context.UserIdentifier!);
        var session = await _sessionService.StartSessionAsync(caregiverId, childId, ct);

        await NotifyChildSessionRequest(session);
        await Clients.Caller.SendAsync("SessionRequested", ToSummary(session), ct);
        return ToSummary(session);
    }

    [Authorize(Roles = "Child")]
    public async Task<SessionSummary> AcceptSession(Guid sessionId, CancellationToken ct)
    {
        var childId = Guid.Parse(Context.UserIdentifier!);
        var session = await _sessionService.AcceptAsync(sessionId, childId, ct);

        await AddSessionGroups(session);
        await Clients.Clients(_connService.GetConnections(session.CaregiverId.ToString()))
            .SendAsync("SessionAccepted", ToSummary(session), ct);
        return ToSummary(session);
    }

    [Authorize(Roles = "Child")]
    public async Task<SessionSummary> DenySession(Guid sessionId, CancellationToken ct)
    {
        var childId = Guid.Parse(Context.UserIdentifier!);
        var session = await _sessionService.DenyAsync(sessionId, childId, ct);

        await Clients.Clients(_connService.GetConnections(session.CaregiverId.ToString()))
            .SendAsync("SessionDenied", ToSummary(session), ct);
        return ToSummary(session);
    }

    [Authorize(Roles = "Child,Caregiver")]
    public async Task<SessionSummary> EndSession(Guid sessionId, CancellationToken ct)
    {
        var userId = Guid.Parse(Context.UserIdentifier!);
        var session = await _sessionService.EndAsync(sessionId, userId, ct);

        await Clients.Group(SessionGroup(sessionId)).SendAsync("SessionEnded", ToSummary(session), ct);
        await RemoveSessionGroups(session);
        return ToSummary(session);
    }

    [Authorize(Roles = "Child")]
    public async Task SendBoardUpdate(BoardUpdateDto update, CancellationToken ct)
    {
        var childId = Guid.Parse(Context.UserIdentifier!);
        var session = await _sessionService.GetAsync(update.SessionId, ct) ?? throw new HubException("Session not found.");
        if (session.ChildId != childId || session.State != SessionState.Active)
            throw new HubException("Session not active or does not belong to child.");

        await Clients.Group(SessionCaregiverGroup(update.SessionId))
            .SendAsync("BoardUpdate", update, ct);
    }

    private async Task NotifyChildSessionRequest(Session session)
    {
        var childConnections = _connService.GetConnections(session.ChildId.ToString());
        await Clients.Clients(childConnections)
            .SendAsync("SessionRequest", new SessionRequestNotification(session.Id, session.CaregiverId));
    }

    private async Task AddSessionGroups(Session session)
    {
        var caregiverGroup = SessionCaregiverGroup(session.Id);
        var childGroup = SessionChildGroup(session.Id);

        foreach (var conn in _connService.GetConnections(session.CaregiverId.ToString()))
            await Groups.AddToGroupAsync(conn, caregiverGroup);

        foreach (var conn in _connService.GetConnections(session.ChildId.ToString()))
        {
            await Groups.AddToGroupAsync(conn, SessionGroup(session.Id)); // shared broadcast
            await Groups.AddToGroupAsync(conn, childGroup);
        }
    }

    private async Task RemoveSessionGroups(Session session)
    {
        var all = _connService.GetConnections(session.CaregiverId.ToString())
            .Concat(_connService.GetConnections(session.ChildId.ToString()));
        foreach (var conn in all)
        {
            await Groups.RemoveFromGroupAsync(conn, SessionGroup(session.Id));
            await Groups.RemoveFromGroupAsync(conn, SessionCaregiverGroup(session.Id));
            await Groups.RemoveFromGroupAsync(conn, SessionChildGroup(session.Id));
        }
    }

    private static string SessionGroup(Guid id) => $"session:{id}";
    private static string SessionCaregiverGroup(Guid id) => $"session:{id}:caregivers";
    private static string SessionChildGroup(Guid id) => $"session:{id}:child";
    private static SessionSummary ToSummary(Session s) => new(s.Id, s.State, s.CaregiverId, s.ChildId);
}