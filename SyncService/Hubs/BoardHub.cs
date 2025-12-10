// SyncService/Hubs/BoardHub.cs

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using SyncService.Models;
using SyncService.Models.ArtifactAdded;
using VTA.API.DbContexts;
using VTA.API.Models;

namespace SyncService.Hubs
{
    [Authorize]
    public class BoardHub(VTAContext dbContext) : Hub
    {
        private static readonly Dictionary<string, string> userConnections = new(); // userId -> connectionId
        private static readonly Dictionary<string, BoardSession> boardSessions = new(); // sessionId -> session
        
        public async Task RegisterUser(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                Console.WriteLine("[Hub] Reject RegisterUser: EMPTY userId");
                return;
            }

            userConnections[userId] = Context.ConnectionId;
            Console.WriteLine($"[Hub] RegisterUser => UserId={userId} Conn={Context.ConnectionId}");
        }

        public async Task RequestSession(string fromUserId, string toUserId)
        {
            Console.WriteLine($"[Hub] RequestSession => {fromUserId} → {toUserId}");

            if (userConnections.TryGetValue(toUserId, out var toConn))
            {
                await Clients.Client(toConn).SendAsync("SessionRequested", fromUserId);
            }
            else
            {
                await Clients.Client(Context.ConnectionId).SendAsync("UserOffline", toUserId);
            }
        }

        public async Task AcceptSession(string sessionId, string fromUserId, string toUserId, string boardId)
        {
            Console.WriteLine($"[Hub] AcceptSession => {sessionId} from {fromUserId} + {toUserId} with boardId={boardId}");

            var session = new BoardSession
            {
                SessionId = sessionId,
                User1Id = fromUserId,
                User2Id = toUserId,
                BoardId = boardId
            };

            // Add CALLER (fromUserId) to group
            if (userConnections.TryGetValue(fromUserId, out var fromConn))
            {
                await Groups.AddToGroupAsync(fromConn, sessionId);
                session.Connections.Add(fromConn);
                Console.WriteLine($"[Hub] Added {fromUserId} to group {sessionId}");
            }
            else
            {
                Console.WriteLine($"[Hub] WARNING: {fromUserId} not found in connections");
            }

            // Add RECEIVER (toUserId - the current user accepting) to group
            if (userConnections.TryGetValue(toUserId, out var toConn))
            {
                await Groups.AddToGroupAsync(toConn, sessionId);
                session.Connections.Add(toConn);
                Console.WriteLine($"[Hub] Added {toUserId} to group {sessionId}");
            }
            else
            {
                Console.WriteLine($"[Hub] WARNING: {toUserId} not found in connections");
            }

            boardSessions[sessionId] = session;

            try
            {
                var dbSession = new Session
                {
                    CallerId = fromUserId,
                    CalleeId = toUserId,
                    StartTime = DateTime.UtcNow,
                    CallStatus = CallStatus.Accepted
                };

                dbContext.Sessions.Add(dbSession);
                await dbContext.SaveChangesAsync();
                Console.WriteLine($"[Hub] Session logged to database with Id={dbSession.Id}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error logging session to database: {ex.Message}");
            }

            // Broadcast to BOTH users in the group
            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId, boardId);
            Console.WriteLine($"[Hub] Broadcasted SessionStarted to group {sessionId} with boardId={boardId}");
        }

        public async Task RejectSession(string fromUserId)
        {
            Console.WriteLine($"[Hub] RejectSession => {fromUserId}");

            var currentUserId = Context.User?.FindFirst("sub")?.Value ?? Context.User?.Identity?.Name;

            if (!string.IsNullOrEmpty(currentUserId))
            {
                try
                {
                    var dbSession = new Session
                    {
                        CallerId = fromUserId,
                        CalleeId = currentUserId,
                        StartTime = DateTime.UtcNow,
                        CallStatus = CallStatus.Rejected
                    };

                    dbContext.Sessions.Add(dbSession);
                    await dbContext.SaveChangesAsync();
                    Console.WriteLine($"[Hub] Rejected session logged to database with Id={dbSession.Id}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Hub] Error logging rejected session to database: {ex.Message}");
                }
            }

            if (userConnections.TryGetValue(fromUserId, out var conn))
                await Clients.Client(conn).SendAsync("SessionRejected");
        }

        public async Task UpdateBoard(string sessionId, object boardData)
        {
            Console.WriteLine($"[Hub] UpdateBoard => sessionId={sessionId}");
            await Clients.OthersInGroup(sessionId).SendAsync("BoardUpdated", boardData);
            Console.WriteLine($"[Hub] Broadcasted BoardUpdated to others in group {sessionId}");
        }

        // ---------------- DELTA UPDATE METHODS ----------------

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
                Console.WriteLine($"[Hub] ArtifactAdded: Unauthorized - no user ID in context");
                return;
            }

            var dbArtefact = await dbContext.Artefacts
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.ArtefactId == artifact.Id && a.UserId == userId);

            if (dbArtefact is null)
            {
                Console.WriteLine($"[Hub] ArtifactAdded: Artefact not found or doesn't belong to user. ArtefactId={artifact.SavedArtefactId}, UserId={userId}");
                return;
            }
            
            // Construct expected URLs from database paths
            var httpContext = Context.GetHttpContext();
            var scheme = httpContext?.Request.Scheme ?? "http";
            var host = httpContext?.Request.Host.ToString() ?? "localhost";

            var expectedImageUrl = string.IsNullOrEmpty(dbArtefact.ImagePath)
                ? null
                : scheme + "://" + host + dbArtefact.ImagePath;
            
            // Verify artifact image and sound URLs match the data from the request
            if (artifact.ImageUrl != expectedImageUrl)
            {
                Console.WriteLine($"[Hub] ArtifactAdded: ImageUrl mismatch. Expected={expectedImageUrl}, Received={artifact.ImageUrl}");
                await Clients.Caller.SendAsync("ArtifactNotAdded", data);
                return;
            }
            
            var expectedSoundUrl = string.IsNullOrEmpty(dbArtefact.SoundPath)
                ? null
                : scheme + "://" + host + dbArtefact.SoundPath;

            if (artifact.SoundUrl != expectedSoundUrl)
            {
                Console.WriteLine($"[Hub] ArtifactAdded: SoundUrl mismatch. Expected={expectedSoundUrl}, Received={artifact.SoundUrl}");
                await Clients.Caller.SendAsync("ArtifactNotAdded", data);
                return;
            }

            Console.WriteLine($"[Hub] ArtifactAdded => sessionId={payload.SessionId}, verified artefact={artifact.Id}");
            await Clients.OthersInGroup(payload.SessionId).SendAsync("ArtifactAdded", data);
        }

        public async Task ArtifactRemoved(JsonElement data)
        {
            string? sessionId = null;
            if (data.TryGetProperty("sessionId", out var sessionIdProp))
            {
                sessionId = sessionIdProp.GetString();
            }

            if (string.IsNullOrEmpty(sessionId))
            {
                Console.WriteLine($"[Hub] ArtifactRemoved: Missing sessionId. Data: {data}");
                return;
            }

            Console.WriteLine($"[Hub] ArtifactRemoved => sessionId={sessionId}");
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactRemoved", data);
        }

        public async Task ArtifactMoved(JsonElement data)
        {
            string? sessionId = null;
            if (data.TryGetProperty("sessionId", out var sessionIdProp))
            {
                sessionId = sessionIdProp.GetString();
            }

            if (string.IsNullOrEmpty(sessionId))
            {
                Console.WriteLine($"[Hub] ArtifactMoved: Missing sessionId. Data: {data}");
                return;
            }

            Console.WriteLine($"[Hub] ArtifactMoved => sessionId={sessionId}");
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactMoved", data);
        }

        public async Task ArtifactResized(JsonElement data)
        {
            string? sessionId = null;
            if (data.TryGetProperty("sessionId", out var sessionIdProp))
            {
                sessionId = sessionIdProp.GetString();
            }

            if (string.IsNullOrEmpty(sessionId))
            {
                Console.WriteLine($"[Hub] ArtifactResized: Missing sessionId. Data: {data}");
                return;
            }

            Console.WriteLine($"[Hub] ArtifactResized => sessionId={sessionId}");
            await Clients.OthersInGroup(sessionId).SendAsync("ArtifactResized", data);
        }

        public async Task LayoutChanged(JsonElement data)
        {
            string? sessionId = null;
            if (data.TryGetProperty("sessionId", out var sessionIdProp))
            {
                sessionId = sessionIdProp.GetString();
            }

            if (string.IsNullOrEmpty(sessionId))
            {
                Console.WriteLine($"[Hub] LayoutChanged: Missing sessionId. Data: {data}");
                return;
            }

            Console.WriteLine($"[Hub] LayoutChanged => sessionId={sessionId}");
            await Clients.OthersInGroup(sessionId).SendAsync("LayoutChanged", data);
        }

        public async Task FieldCountChanged(JsonElement data)
        {
            string? sessionId = null;
            if (data.TryGetProperty("sessionId", out var sessionIdProp))
            {
                sessionId = sessionIdProp.GetString();
            }

            if (string.IsNullOrEmpty(sessionId))
            {
                Console.WriteLine($"[Hub] FieldCountChanged: Missing sessionId. Data: {data}");
                return;
            }

            int? count = null;
            if (data.TryGetProperty("count", out var countProp))
            {
                count = countProp.GetInt32();
            }

            Console.WriteLine($"[Hub] FieldCountChanged => sessionId={sessionId}, count={count}");
            await Clients.OthersInGroup(sessionId).SendAsync("FieldCountChanged", data);
        }

        public async Task EndSession(string sessionId)
        {
            Console.WriteLine($"[Hub] EndSession => {sessionId}");

            if (boardSessions.TryGetValue(sessionId, out var boardSession))
            {
                try
                {
                    var dbSession = await dbContext.Sessions
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
                        dbSession.CallStatus = CallStatus.Completed;

                        await dbContext.SaveChangesAsync();
                        Console.WriteLine($"[Hub] Session {dbSession.Id} ended. Duration: {dbSession.Duration}");
                    }
                    else
                    {
                        Console.WriteLine($"[Hub] No matching database session found for sessionId={sessionId}");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Hub] Error updating session end time in database: {ex.Message}");
                }
            }

            await Clients.Group(sessionId).SendAsync("SessionEnded");
            boardSessions.Remove(sessionId);
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var user = userConnections.FirstOrDefault(x => x.Value == Context.ConnectionId).Key;
            if (user != null)
            {
                userConnections.Remove(user);
                Console.WriteLine($"[Hub] User disconnected => {user}");

                var userSessions = boardSessions.Where(s => s.Value.User1Id == user || s.Value.User2Id == user).ToList();
                foreach (var sessionKvp in userSessions)
                {
                    var boardSession = sessionKvp.Value;
                    try
                    {
                        var dbSession = await dbContext.Sessions
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
                            dbSession.CallStatus = CallStatus.Failed;
                            await dbContext.SaveChangesAsync();
                            Console.WriteLine($"[Hub] Session {dbSession.Id} marked as failed due to disconnection");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[Hub] Error updating session on disconnect: {ex.Message}");
                    }

                    boardSessions.Remove(sessionKvp.Key);
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        // WebRTC Signaling Methods
        public async Task SendOffer(string sessionId, string targetUserId, object sdpOffer)
        {
            Console.WriteLine($"[Hub] SendOffer => sessionId={sessionId}, target={targetUserId}");

            if (userConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveOffer", sessionId, sdpOffer);
                Console.WriteLine($"[Hub] Sent offer to {targetUserId}");
            }
            else
            {
                Console.WriteLine($"[Hub] Target user {targetUserId} not connected");
            }
        }

        public async Task SendAnswer(string sessionId, string targetUserId, object sdpAnswer)
        {
            Console.WriteLine($"[Hub] SendAnswer => sessionId={sessionId}, target={targetUserId}");

            if (userConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveAnswer", sessionId, sdpAnswer);
                Console.WriteLine($"[Hub] Sent answer to {targetUserId}");
            }
        }

        public async Task SendIceCandidate(string sessionId, string targetUserId, object candidate)
        {
            Console.WriteLine($"[Hub] SendIceCandidate => sessionId={sessionId}, target={targetUserId}");

            if (userConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveIceCandidate", sessionId, candidate);
            }
        }
    }
}