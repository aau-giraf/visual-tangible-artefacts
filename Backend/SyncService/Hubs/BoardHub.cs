// SyncService/Hubs/BoardHub.cs

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SyncService.Models;
using SyncService.Models.ArtifactAdded;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace SyncService.Hubs
{
    [Authorize]
    public class BoardHub(VTAContext context) : Hub
    {
        private static readonly Dictionary<string, string> userConnections = new();
        private static readonly Dictionary<string, BoardSession> boardSessions = new();
        private static readonly HashSet<string> onlineUsers = new();
        private static readonly Dictionary<string, List<string>> userContactsMap = new();
        private static readonly Dictionary<string, UserInfo> userInfoMap = new(); 
        private static readonly Dictionary<string, PendingSessionRequest> pendingRequests = new(); 

        public async Task RegisterUser(string userId, List<string> contactIds)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                Console.WriteLine("[Hub] Reject RegisterUser: EMPTY userId");
                return;
            }

            userConnections[userId] = Context.ConnectionId;
            onlineUsers.Add(userId);
            userContactsMap[userId] = contactIds ?? new List<string>();
            
            var userName = Context.User?.FindFirst("name")?.Value ?? Context.User?.FindFirst("username")?.Value ?? "User";
            userInfoMap[userId] = new UserInfo { UserId = userId, Name = userName };
            
            Console.WriteLine($"[Hub] RegisterUser => UserId={userId} Name={userName} Conn={Context.ConnectionId} with {contactIds?.Count ?? 0} contacts");
            
            await NotifyContactsOfStatusChange(userId, true);
        }

        private async Task NotifyContactsOfStatusChange(string userId, bool isOnline)
        {
            try
            {
                if (!userContactsMap.TryGetValue(userId, out var contactIds))
                {
                    return;
                }

                Console.WriteLine($"[Hub] NotifyContactsOfStatusChange => userId={userId} isOnline={isOnline} with {contactIds.Count} contacts");
                
                foreach (var contactId in contactIds)
                {
                    if (userConnections.TryGetValue(contactId, out var contactConn))
                    {
                        await Clients.Client(contactConn).SendAsync("UserOnlineStatusChanged", userId, isOnline);
                        Console.WriteLine($"[Hub]   Notified {contactId} that {userId} is {(isOnline ? "online" : "offline")}");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error notifying contacts: {ex.Message}");
            }
        }

        public List<string> GetOnlineUsers()
        {
            var onlineList = onlineUsers.ToList();
            Console.WriteLine($"[Hub] GetOnlineUsers => Returning {onlineList.Count} online users");
            return onlineList;
        }

        public bool IsUserOnline(string userId)
        {
            var isOnline = onlineUsers.Contains(userId);
            Console.WriteLine($"[Hub] IsUserOnline => userId={userId} isOnline={isOnline}");
            return isOnline;
        }

        public async Task RequestSession(string fromUserId, string toUserId)
        {
            Console.WriteLine($"[Hub] RequestSession => {fromUserId} → {toUserId}");

            var requestKey = $"{fromUserId}_{toUserId}_{DateTime.UtcNow.Ticks}";
            var cts = new CancellationTokenSource();
            
            var request = new PendingSessionRequest
            {
                FromUserId = fromUserId,
                ToUserId = toUserId,
                RequestTime = DateTime.UtcNow,
                TimeoutCts = cts
            };
            
            pendingRequests[requestKey] = request;

            if (userConnections.TryGetValue(toUserId, out var toConn))
            {
                await Clients.Client(toConn).SendAsync("SessionRequested", fromUserId);
                Console.WriteLine($"[Hub] Sent SessionRequested to {toUserId}");
                
                // Capture clients and connection ID before async task
                var clients = Clients;
                var connectionId = toConn;
                
                // Start 30-second timeout for missed call
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await Task.Delay(30000, cts.Token);
                        
                        Console.WriteLine($"[Hub] Session request timed out - sending missed call notification");
                        
                        // Check if it's still pending (not accepted or rejected)
                        if (pendingRequests.ContainsKey(requestKey))
                        {
                            pendingRequests.Remove(requestKey);
                            
                            // Get the caller's name from stored user info
                            var callerName = await GetUserName(fromUserId);
                            
                            // Check if connection still exists before sending
                            if (userConnections.ContainsValue(connectionId))
                            {
                                try
                                {
                                    await clients.Client(connectionId).SendAsync(
                                        "MissedCall", 
                                        fromUserId, 
                                        callerName
                                    );
                                    Console.WriteLine($"[Hub] Sent MissedCall notification to {toUserId} from {callerName}");
                                }
                                catch (Exception ex)
                                {
                                    Console.WriteLine($"[Hub] Failed to send MissedCall notification: {ex.Message}");
                                }
                            }
                            else
                            {
                                Console.WriteLine($"[Hub] User {toUserId} disconnected before MissedCall could be sent");
                            }
                        }
                    }
                    catch (OperationCanceledException)
                    {
                        Console.WriteLine($"[Hub] Timeout cancelled for {requestKey}");
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
                pendingRequests.Remove(requestKey);
                Console.WriteLine($"[Hub] User {toUserId} is offline");
            }
        }

        private async Task<string> GetUserName(string userId)
        {
            try
            {
                if (userInfoMap.TryGetValue(userId, out var userInfo))
                {
                    return userInfo.Name;
                }
                return "User";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error getting user name: {ex.Message}");
                return "User";
            }
        }

        public async Task AcceptSession(string sessionId, string fromUserId, string toUserId, string boardId)
        {
            Console.WriteLine($"[Hub] AcceptSession => {sessionId} from {fromUserId} + {toUserId} with boardId={boardId}");

            var keysToRemove = pendingRequests
                .Where(x => x.Value.FromUserId == fromUserId && x.Value.ToUserId == toUserId)
                .Select(x => x.Key)
                .ToList();
            
            foreach (var key in keysToRemove)
            {
                if (pendingRequests.TryGetValue(key, out var request))
                {
                    request.TimeoutCts.Cancel();
                    pendingRequests.Remove(key);
                    Console.WriteLine($"[Hub] Cancelled pending timeout for {fromUserId}");
                }
            }

            var session = new BoardSession
            {
                SessionId = sessionId,
                User1Id = fromUserId,
                User2Id = toUserId,
                BoardId = boardId
            };

            if (userConnections.TryGetValue(fromUserId, out var fromConn))
            {
                await Groups.AddToGroupAsync(fromConn, sessionId);
                session.Connections.Add(fromConn);
                Console.WriteLine($"[Hub] Added {fromUserId} to group {sessionId}");
            }

            if (userConnections.TryGetValue(toUserId, out var toConn))
            {
                await Groups.AddToGroupAsync(toConn, sessionId);
                session.Connections.Add(toConn);
                Console.WriteLine($"[Hub] Added {toUserId} to group {sessionId}");
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

                context.Sessions.Add(dbSession);
                await context.SaveChangesAsync();
                Console.WriteLine($"[Hub] Session logged to database with Id={dbSession.Id}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Hub] Error logging session to database: {ex.Message}");
            }

            // Broadcast to BOTH users in the group
            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId, boardId);
            Console.WriteLine($"[Hub] Broadcasted SessionStarted to group {sessionId}");
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

                    context.Sessions.Add(dbSession);
                    await context.SaveChangesAsync();
                    Console.WriteLine($"[Hub] Rejected session logged to database with Id={dbSession.Id}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Hub] Error logging rejected session to database: {ex.Message}");
                }
            }

            var keysToRemove = pendingRequests
                .Where(x => x.Value.FromUserId == fromUserId)
                .Select(x => x.Key)
                .ToList();
            
            foreach (var key in keysToRemove)
            {
                if (pendingRequests.TryGetValue(key, out var request))
                {
                    request.TimeoutCts.Cancel();
                    pendingRequests.Remove(key);
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

            var dbArtefact = await context.Artefacts
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
                await Clients.Caller.SendAsync("ArtifactRejected", data);
                return;
            }
            
            var expectedSoundUrl = string.IsNullOrEmpty(dbArtefact.SoundPath)
                ? null
                : scheme + "://" + host + dbArtefact.SoundPath;

            if (artifact.SoundUrl != expectedSoundUrl)
            {
                Console.WriteLine($"[Hub] ArtifactAdded: SoundUrl mismatch. Expected={expectedSoundUrl}, Received={artifact.SoundUrl}");
                await Clients.Caller.SendAsync("ArtifactRejected", data);
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
                        dbSession.CallStatus = CallStatus.Completed;

                        await context.SaveChangesAsync();
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
                Console.WriteLine($"[Hub] User disconnected => {user}");

                var userSessions = boardSessions.Where(s => s.Value.User1Id == user || s.Value.User2Id == user).ToList();
                foreach (var sessionKvp in userSessions)
                {
                    var boardSession = sessionKvp.Value;
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
                            dbSession.CallStatus = CallStatus.Failed;
                            await context.SaveChangesAsync();
                            Console.WriteLine($"[Hub] Session {dbSession.Id} marked as failed due to disconnection");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[Hub] Error updating session on disconnect: {ex.Message}");
                    }

                    boardSessions.Remove(sessionKvp.Key);
                }
                
                await NotifyContactsOfStatusChange(user, false);
                
                userConnections.Remove(user);
                onlineUsers.Remove(user);
                userContactsMap.Remove(user);
                userInfoMap.Remove(user); 
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