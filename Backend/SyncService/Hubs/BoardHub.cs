// SyncService/Hubs/BoardHub.cs
//
// Thin dispatcher — delegates state management to:
//   IPresenceService  (connection tracking, online status)
//   ISessionService   (pending requests, active sessions)
//   IBoardSyncRelay   (sessionId extraction for relay events)
//
// DB operations (VTAContext) stay here because the Hub is scoped per-invocation.

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SyncService.Models.ArtifactAdded;
using SyncService.Services;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace SyncService.Hubs
{
    [Authorize]
    public class BoardHub(
        VTAContext context,
        IPresenceService presence,
        ISessionService sessions,
        IBoardSyncRelay syncRelay) : Hub
    {
        // ── Presence ────────────────────────────────────────────────

        public async Task RegisterUser(string userId, List<string> contactIds)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                Console.WriteLine("[Hub] Reject RegisterUser: EMPTY userId");
                return;
            }

            var userName = Context.User?.FindFirst("name")?.Value
                           ?? Context.User?.FindFirst("username")?.Value
                           ?? "User";

            presence.TrackConnection(userId, Context.ConnectionId, contactIds, userName);
            Console.WriteLine($"[Hub] RegisterUser => UserId={userId} Name={userName} Conn={Context.ConnectionId} with {contactIds?.Count ?? 0} contacts");

            await NotifyContactsOfStatusChange(userId, true);
        }

        public List<string> GetOnlineUsers()
        {
            var onlineList = presence.GetOnlineUsers();
            Console.WriteLine($"[Hub] GetOnlineUsers => Returning {onlineList.Count} online users");
            return onlineList;
        }

        public bool IsUserOnline(string userId)
        {
            var isOnline = presence.IsUserOnline(userId);
            Console.WriteLine($"[Hub] IsUserOnline => userId={userId} isOnline={isOnline}");
            return isOnline;
        }

        // ── Session lifecycle ───────────────────────────────────────

        public async Task RequestSession(string fromUserId, string toUserId)
        {
            Console.WriteLine($"[Hub] RequestSession => {fromUserId} → {toUserId}");

            var requestKey = sessions.CreatePendingRequest(fromUserId, toUserId);

            if (presence.TryGetConnection(toUserId, out var toConn))
            {
                await Clients.Client(toConn).SendAsync("SessionRequested", fromUserId);
                Console.WriteLine($"[Hub] Sent SessionRequested to {toUserId}");

                var clients = Clients;
                var connectionId = toConn;

                _ = Task.Run(async () =>
                {
                    try
                    {
                        await Task.Delay(30000);

                        if (sessions.IsPending(requestKey))
                        {
                            sessions.RemovePendingRequest(requestKey);
                            var callerName = presence.GetUserName(fromUserId);

                            if (presence.IsConnectionActive(connectionId))
                            {
                                try
                                {
                                    await clients.Client(connectionId).SendAsync("MissedCall", fromUserId, callerName);
                                    Console.WriteLine($"[Hub] Sent MissedCall notification to {toUserId} from {callerName}");
                                }
                                catch (Exception ex)
                                {
                                    Console.WriteLine($"[Hub] Failed to send MissedCall notification: {ex.Message}");
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[Hub] Error in timeout: {ex.Message}");
                    }
                });
            }
            else
            {
                await Clients.Client(Context.ConnectionId).SendAsync("UserOffline", toUserId);
                sessions.RemovePendingRequest(requestKey);
                Console.WriteLine($"[Hub] User {toUserId} is offline");
            }
        }

        public async Task AcceptSession(string sessionId, string fromUserId, string toUserId, string boardId)
        {
            Console.WriteLine($"[Hub] AcceptSession => {sessionId} from {fromUserId} + {toUserId} with boardId={boardId}");

            sessions.CancelPendingRequests(fromUserId, toUserId);

            var session = new Models.BoardSession
            {
                SessionId = sessionId,
                User1Id = fromUserId,
                User2Id = toUserId,
                BoardId = boardId
            };

            if (presence.TryGetConnection(fromUserId, out var fromConn))
            {
                await Groups.AddToGroupAsync(fromConn, sessionId);
                session.Connections.Add(fromConn);
            }

            if (presence.TryGetConnection(toUserId, out var toConn))
            {
                await Groups.AddToGroupAsync(toConn, sessionId);
                session.Connections.Add(toConn);
            }

            sessions.AddSession(session);

            try
            {
                context.Sessions.Add(new Session
                {
                    CallerId = fromUserId,
                    CalleeId = toUserId,
                    StartTime = DateTime.UtcNow,
                    CallStatus = CallStatus.Accepted
                });
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error logging session to database: {ex.Message}");
            }

            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId, boardId);
        }

        public async Task RejectSession(string fromUserId)
        {
            Console.WriteLine($"[Hub] RejectSession => {fromUserId}");

            var currentUserId = Context.User?.FindFirst("sub")?.Value ?? Context.User?.Identity?.Name;

            if (!string.IsNullOrEmpty(currentUserId))
            {
                try
                {
                    context.Sessions.Add(new Session
                    {
                        CallerId = fromUserId,
                        CalleeId = currentUserId,
                        StartTime = DateTime.UtcNow,
                        CallStatus = CallStatus.Rejected
                    });
                    await context.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Hub] Error logging rejected session to database: {ex.Message}");
                }
            }

            sessions.CancelPendingRequests(fromUserId);

            if (presence.TryGetConnection(fromUserId, out var conn))
                await Clients.Client(conn).SendAsync("SessionRejected");
        }

        public async Task EndSession(string sessionId)
        {
            Console.WriteLine($"[Hub] EndSession => {sessionId}");

            if (sessions.TryGetSession(sessionId, out var boardSession))
            {
                await UpdateSessionEndInDb(boardSession, CallStatus.Completed);
            }

            await Clients.Group(sessionId).SendAsync("SessionEnded");
            sessions.RemoveSession(sessionId);
        }

        // ── Board sync relay ────────────────────────────────────────

        public async Task UpdateBoard(string sessionId, object boardData)
        {
            await Clients.OthersInGroup(sessionId).SendAsync("BoardUpdated", boardData);
        }

        public async Task ArtifactAdded(JsonElement data)
        {
            var payload = data.Deserialize<ArtifactAddedPayload>(new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (string.IsNullOrEmpty(payload?.SessionId))
            {
                Console.WriteLine($"[Hub] ArtifactAdded: Missing sessionId. Data: {data}");
                return;
            }

            var artifact = payload.Artifact;
            var userId = Context.User?.FindFirst("id")?.Value;

            if (string.IsNullOrEmpty(userId))
            {
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Unauthorized: No user ID in context");
                return;
            }

            var dbArtefact = await context.Artefacts
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.ArtefactId == artifact.Id && a.UserId == userId);

            if (dbArtefact is null)
            {
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Artifact not found or does not belong to you");
                return;
            }

            if (!string.IsNullOrWhiteSpace(dbArtefact.ImagePath) && (!artifact.ImageUrl?.EndsWith(dbArtefact.ImagePath) ?? false))
            {
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Image URL mismatch");
                return;
            }

            if (!string.IsNullOrWhiteSpace(dbArtefact.SoundPath) && (!artifact.ImageUrl?.EndsWith(dbArtefact.SoundPath) ?? false))
            {
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Sound URL mismatch");
                return;
            }

            await Clients.OthersInGroup(payload.SessionId).SendAsync("ArtifactAdded", data);
        }

        public async Task ArtifactRemoved(JsonElement data)
        {
            var sessionId = syncRelay.ExtractSessionId(data);
            if (string.IsNullOrEmpty(sessionId)) return;
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactRemoved", data);
        }

        public async Task ArtifactMoved(JsonElement data)
        {
            var sessionId = syncRelay.ExtractSessionId(data);
            if (string.IsNullOrEmpty(sessionId)) return;
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactMoved", data);
        }

        public async Task ArtifactResized(JsonElement data)
        {
            var sessionId = syncRelay.ExtractSessionId(data);
            if (string.IsNullOrEmpty(sessionId)) return;
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactResized", data);
        }

        public async Task LayoutChanged(JsonElement data)
        {
            var sessionId = syncRelay.ExtractSessionId(data);
            if (string.IsNullOrEmpty(sessionId)) return;
            await Clients.OthersInGroup(sessionId).SendAsync("LayoutChanged", data);
        }

        public async Task FieldCountChanged(JsonElement data)
        {
            var sessionId = syncRelay.ExtractSessionId(data);
            if (string.IsNullOrEmpty(sessionId)) return;
            await Clients.OthersInGroup(sessionId).SendAsync("FieldCountChanged", data);
        }

        // ── WebRTC signaling ────────────────────────────────────────

        public async Task SendOffer(string sessionId, string targetUserId, object sdpOffer)
        {
            if (presence.TryGetConnection(targetUserId, out var targetConn))
                await Clients.Client(targetConn).SendAsync("ReceiveOffer", sessionId, sdpOffer);
        }

        public async Task SendAnswer(string sessionId, string targetUserId, object sdpAnswer)
        {
            if (presence.TryGetConnection(targetUserId, out var targetConn))
                await Clients.Client(targetConn).SendAsync("ReceiveAnswer", sessionId, sdpAnswer);
        }

        public async Task SendIceCandidate(string sessionId, string targetUserId, object candidate)
        {
            if (presence.TryGetConnection(targetUserId, out var targetConn))
                await Clients.Client(targetConn).SendAsync("ReceiveIceCandidate", sessionId, candidate);
        }

        // ── Disconnect ──────────────────────────────────────────────

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = presence.RemoveConnection(Context.ConnectionId);

            if (userId != null)
            {
                Console.WriteLine($"[Hub] User disconnected => {userId}");

                foreach (var sessionKvp in sessions.GetSessionsForUser(userId))
                {
                    await UpdateSessionEndInDb(sessionKvp.Value, CallStatus.Failed);
                    sessions.RemoveSession(sessionKvp.Key);
                }

                await NotifyContactsOfStatusChange(userId, false);
            }

            await base.OnDisconnectedAsync(exception);
        }

        // ── Private helpers ─────────────────────────────────────────

        private async Task NotifyContactsOfStatusChange(string userId, bool isOnline)
        {
            try
            {
                var contactIds = presence.GetContactIds(userId);
                foreach (var contactId in contactIds)
                {
                    if (presence.TryGetConnection(contactId, out var contactConn))
                    {
                        await Clients.Client(contactConn).SendAsync("UserOnlineStatusChanged", userId, isOnline);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error notifying contacts: {ex.Message}");
            }
        }

        private async Task UpdateSessionEndInDb(Models.BoardSession boardSession, CallStatus status)
        {
            try
            {
                var dbSession = await context.Sessions
                    .Where(s => (s.CallerId == boardSession.User1Id && s.CalleeId == boardSession.User2Id) ||
                                (s.CallerId == boardSession.User2Id && s.CalleeId == boardSession.User1Id))
                    .Where(s => s.CallStatus == CallStatus.Accepted)
                    .OrderByDescending(s => s.StartTime)
                    .FirstOrDefaultAsync();

                if (dbSession != null)
                {
                    dbSession.EndTime = DateTime.UtcNow;
                    if (dbSession.StartTime.HasValue)
                    {
                        dbSession.Duration = dbSession.EndTime.Value - dbSession.StartTime.Value;
                    }
                    dbSession.CallStatus = status;
                    await context.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error updating session in database: {ex.Message}");
            }
        }
    }
}