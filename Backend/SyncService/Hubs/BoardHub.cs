// SyncService/Hubs/BoardHub.cs

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SyncService.Models;
using SyncService.Models.ArtifactAdded;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace SyncService.Hubs
{
    [Authorize]
    public class BoardHub(VTAContext context, ILogger<BoardHub> logger) : Hub
    {
        private static readonly Dictionary<string, string> UserConnections = new();
        private static readonly Dictionary<string, BoardSession> BoardSessions = new();
        private static readonly HashSet<string> OnlineUsers = new();
        private static readonly Dictionary<string, List<string>> UserContactsMap = new();
        private static readonly Dictionary<string, UserInfo> UserInfoMap = new(); 
        private static readonly Dictionary<string, PendingSessionRequest> PendingRequests = new(); 

        public async Task RegisterUser(string userId, List<string> contactIds)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                logger.LogWarning("Reject RegisterUser: EMPTY userId");
                return;
            }

            UserConnections[userId] = Context.ConnectionId;
            OnlineUsers.Add(userId);
            UserContactsMap[userId] = contactIds ?? new List<string>();

            var userName = Context.User?.FindFirst("name")?.Value ?? Context.User?.FindFirst("username")?.Value ?? "User";
            UserInfoMap[userId] = new UserInfo { UserId = userId, Name = userName };

            logger.LogInformation("RegisterUser => UserId={UserId} Name={UserName} Conn={ConnectionId} with {ContactCount} contacts",
                userId, userName, Context.ConnectionId, contactIds?.Count ?? 0);

            await NotifyContactsOfStatusChange(userId, true);
        }

        private async Task NotifyContactsOfStatusChange(string userId, bool isOnline)
        {
            try
            {
                if (!UserContactsMap.TryGetValue(userId, out var contactIds))
                {
                    return;
                }

                logger.LogDebug("NotifyContactsOfStatusChange => UserId={UserId} IsOnline={IsOnline} with {ContactCount} contacts",
                    userId, isOnline, contactIds.Count);

                foreach (var contactId in contactIds)
                {
                    if (UserConnections.TryGetValue(contactId, out var contactConn))
                    {
                        await Clients.Client(contactConn).SendAsync("UserOnlineStatusChanged", userId, isOnline);
                        logger.LogDebug("Notified {ContactId} that {UserId} is {Status}", contactId, userId, isOnline ? "online" : "offline");
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error notifying contacts for UserId={UserId}", userId);
            }
        }

        public List<string> GetOnlineUsers()
        {
            var onlineList = OnlineUsers.ToList();
            logger.LogDebug("GetOnlineUsers => Returning {OnlineUserCount} online users", onlineList.Count);
            return onlineList;
        }

        public bool IsUserOnline(string userId)
        {
            var isOnline = OnlineUsers.Contains(userId);
            logger.LogDebug("IsUserOnline => UserId={UserId} IsOnline={IsOnline}", userId, isOnline);
            return isOnline;
        }

        public async Task RequestSession(string fromUserId, string toUserId)
        {
            logger.LogInformation("RequestSession => {FromUserId} -> {ToUserId}", fromUserId, toUserId);

            var requestKey = $"{fromUserId}_{toUserId}_{DateTime.UtcNow.Ticks}";
            var cts = new CancellationTokenSource();

            var request = new PendingSessionRequest
            {
                FromUserId = fromUserId,
                ToUserId = toUserId,
                RequestTime = DateTime.UtcNow,
                TimeoutCts = cts
            };

            PendingRequests[requestKey] = request;

            if (UserConnections.TryGetValue(toUserId, out var toConn))
            {
                await Clients.Client(toConn).SendAsync("SessionRequested", fromUserId);
                logger.LogInformation("Sent SessionRequested to {ToUserId}", toUserId);

                // Capture clients and connection ID before async task
                var clients = Clients;
                var connectionId = toConn;

                // Start 30-second timeout for missed call
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await Task.Delay(30000, cts.Token);

                        logger.LogInformation("Session request timed out - sending missed call notification");

                        // Check if it's still pending (not accepted or rejected)
                        if (PendingRequests.ContainsKey(requestKey))
                        {
                            PendingRequests.Remove(requestKey);

                            // Get the caller's name from stored user info
                            var callerName = await GetUserName(fromUserId);

                            // Check if connection still exists before sending
                            if (UserConnections.ContainsValue(connectionId))
                            {
                                try
                                {
                                    await clients.Client(connectionId).SendAsync(
                                        "MissedCall",
                                        fromUserId,
                                        callerName
                                    );
                                    logger.LogInformation("Sent MissedCall notification to {ToUserId} from {CallerName}", toUserId, callerName);
                                }
                                catch (Exception ex)
                                {
                                    logger.LogError(ex, "Failed to send MissedCall notification to {ToUserId}", toUserId);
                                }
                            }
                            else
                            {
                                logger.LogWarning("User {ToUserId} disconnected before MissedCall could be sent", toUserId);
                            }
                        }
                    }
                    catch (OperationCanceledException)
                    {
                        logger.LogDebug("Timeout cancelled for {RequestKey}", requestKey);
                    }
                    catch (Exception ex)
                    {
                        logger.LogError(ex, "Error in timeout for {RequestKey}", requestKey);
                    }
                });
            }
            else
            {
                await Clients.Client(Context.ConnectionId).SendAsync("UserOffline", toUserId);
                PendingRequests.Remove(requestKey);
                logger.LogInformation("User {ToUserId} is offline", toUserId);
            }
        }

        private Task<string> GetUserName(string userId)
        {
            try
            {
                if (UserInfoMap.TryGetValue(userId, out var userInfo))
                {
                    return Task.FromResult(userInfo.Name);
                }
                return Task.FromResult("User");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error getting user name for UserId={UserId}", userId);
                return Task.FromResult("User");
            }
        }

        public async Task AcceptSession(string sessionId, string fromUserId, string toUserId, string boardId)
        {
            logger.LogInformation("AcceptSession => SessionId={SessionId} from {FromUserId} + {ToUserId} with BoardId={BoardId}",
                sessionId, fromUserId, toUserId, boardId);

            var keysToRemove = PendingRequests
                .Where(x => x.Value.FromUserId == fromUserId && x.Value.ToUserId == toUserId)
                .Select(x => x.Key)
                .ToList();

            foreach (var key in keysToRemove)
            {
                if (PendingRequests.TryGetValue(key, out var request))
                {
                    request.TimeoutCts.Cancel();
                    PendingRequests.Remove(key);
                    logger.LogDebug("Cancelled pending timeout for {FromUserId}", fromUserId);
                }
            }

            var session = new BoardSession
            {
                SessionId = sessionId,
                User1Id = fromUserId,
                User2Id = toUserId,
                BoardId = boardId
            };

            if (UserConnections.TryGetValue(fromUserId, out var fromConn))
            {
                await Groups.AddToGroupAsync(fromConn, sessionId);
                session.Connections.Add(fromConn);
                logger.LogDebug("Added {FromUserId} to group {SessionId}", fromUserId, sessionId);
            }

            if (UserConnections.TryGetValue(toUserId, out var toConn))
            {
                await Groups.AddToGroupAsync(toConn, sessionId);
                session.Connections.Add(toConn);
                logger.LogDebug("Added {ToUserId} to group {SessionId}", toUserId, sessionId);
            }

            BoardSessions[sessionId] = session;

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
                logger.LogInformation("Session logged to database with Id={SessionDbId}", dbSession.Id);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error logging session to database for SessionId={SessionId}", sessionId);
            }

            // Broadcast to BOTH users in the group
            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId, boardId);
            logger.LogInformation("Broadcasted SessionStarted to group {SessionId}", sessionId);
        }

        public async Task RejectSession(string fromUserId)
        {
            logger.LogInformation("RejectSession => {FromUserId}", fromUserId);

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
                    logger.LogInformation("Rejected session logged to database with Id={SessionDbId}", dbSession.Id);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Error logging rejected session to database for {FromUserId}", fromUserId);
                }
            }

            var keysToRemove = PendingRequests
                .Where(x => x.Value.FromUserId == fromUserId)
                .Select(x => x.Key)
                .ToList();

            foreach (var key in keysToRemove)
            {
                if (PendingRequests.TryGetValue(key, out var request))
                {
                    request.TimeoutCts.Cancel();
                    PendingRequests.Remove(key);
                }
            }

            if (UserConnections.TryGetValue(fromUserId, out var conn))
                await Clients.Client(conn).SendAsync("SessionRejected");
        }

        public async Task UpdateBoard(string sessionId, object boardData)
        {
            logger.LogDebug("UpdateBoard => SessionId={SessionId}", sessionId);
            await Clients.OthersInGroup(sessionId).SendAsync("BoardUpdated", boardData);
            logger.LogDebug("Broadcasted BoardUpdated to others in group {SessionId}", sessionId);
        }

        public async Task ArtifactAdded(JsonElement data)
        {
            var payload = data.Deserialize<ArtifactAddedPayload>(new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (string.IsNullOrEmpty(payload?.SessionId))
            {
                logger.LogWarning("ArtifactAdded: Missing sessionId. Data: {Data}", data);
                return;
            }

            var artifact = payload.Artifact;

            var userId = Context.User?.FindFirst("id")?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                logger.LogWarning("ArtifactAdded: Unauthorized - no user ID in context");
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Unauthorized: No user ID in context");
                return;
            }

            var dbArtefact = await context.Artefacts
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.ArtefactId == artifact.Id && a.UserId == userId);

            if (dbArtefact is null)
            {
                logger.LogWarning("ArtifactAdded: Artefact not found or doesn't belong to user. ArtefactId={ArtefactId}, UserId={UserId}",
                    artifact.SavedArtefactId, userId);
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Artifact not found or does not belong to you");
                return;
            }

            // Verify artifact image and sound URLs match the data from the request
            if (!string.IsNullOrWhiteSpace(dbArtefact.ImagePath) && (!artifact.ImageUrl?.EndsWith(dbArtefact.ImagePath) ?? false))
            {
                logger.LogWarning("ArtifactAdded: ImageUrl mismatch. Expected={ExpectedPath}, Received={ReceivedUrl}",
                    dbArtefact.ImagePath, artifact.ImageUrl);
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Image URL mismatch");
                return;
            }

            if (!string.IsNullOrWhiteSpace(dbArtefact.SoundPath) && (!artifact.ImageUrl?.EndsWith(dbArtefact.SoundPath) ?? false))
            {
                logger.LogWarning("ArtifactAdded: SoundUrl mismatch. Expected={ExpectedPath}, Received={ReceivedUrl}",
                    dbArtefact.SoundPath, artifact.SoundUrl);
                await Clients.Caller.SendAsync("ArtifactRejected", data, "Sound URL mismatch");
                return;
            }

            logger.LogDebug("ArtifactAdded => SessionId={SessionId}, verified ArtefactId={ArtefactId}", payload.SessionId, artifact.Id);
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
                logger.LogWarning("ArtifactRemoved: Missing sessionId. Data: {Data}", data);
                return;
            }

            logger.LogDebug("ArtifactRemoved => SessionId={SessionId}", sessionId);
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
                logger.LogWarning("ArtifactMoved: Missing sessionId. Data: {Data}", data);
                return;
            }

            logger.LogDebug("ArtifactMoved => SessionId={SessionId}", sessionId);
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
                logger.LogWarning("ArtifactResized: Missing sessionId. Data: {Data}", data);
                return;
            }

            logger.LogDebug("ArtifactResized => SessionId={SessionId}", sessionId);
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
                logger.LogWarning("LayoutChanged: Missing sessionId. Data: {Data}", data);
                return;
            }

            logger.LogDebug("LayoutChanged => SessionId={SessionId}", sessionId);
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
                logger.LogWarning("FieldCountChanged: Missing sessionId. Data: {Data}", data);
                return;
            }

            int? count = null;
            if (data.TryGetProperty("count", out var countProp))
            {
                count = countProp.GetInt32();
            }

            logger.LogDebug("FieldCountChanged => SessionId={SessionId}, Count={Count}", sessionId, count);
            await Clients.OthersInGroup(sessionId).SendAsync("FieldCountChanged", data);
        }

        public async Task EndSession(string sessionId)
        {
            logger.LogInformation("EndSession => SessionId={SessionId}", sessionId);

            if (BoardSessions.TryGetValue(sessionId, out var boardSession))
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
                        logger.LogInformation("Session {SessionDbId} ended. Duration: {Duration}", dbSession.Id, dbSession.Duration);
                    }
                    else
                    {
                        logger.LogWarning("No matching database session found for SessionId={SessionId}", sessionId);
                    }
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Error updating session end time in database for SessionId={SessionId}", sessionId);
                }
            }

            await Clients.Group(sessionId).SendAsync("SessionEnded");
            BoardSessions.Remove(sessionId);
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var user = UserConnections.FirstOrDefault(x => x.Value == Context.ConnectionId).Key;
            if (user != null)
            {
                logger.LogInformation("User disconnected => UserId={UserId}", user);

                var userSessions = BoardSessions.Where(s => s.Value.User1Id == user || s.Value.User2Id == user).ToList();
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
                            logger.LogInformation("Session {SessionDbId} marked as failed due to disconnection", dbSession.Id);
                        }
                    }
                    catch (Exception ex)
                    {
                        logger.LogError(ex, "Error updating session on disconnect for UserId={UserId}", user);
                    }

                    BoardSessions.Remove(sessionKvp.Key);
                }

                await NotifyContactsOfStatusChange(user, false);

                UserConnections.Remove(user);
                OnlineUsers.Remove(user);
                UserContactsMap.Remove(user);
                UserInfoMap.Remove(user);
            }

            await base.OnDisconnectedAsync(exception);
        }

        // WebRTC Signaling Methods
        public async Task SendOffer(string sessionId, string targetUserId, object sdpOffer)
        {
            logger.LogDebug("SendOffer => SessionId={SessionId}, TargetUserId={TargetUserId}", sessionId, targetUserId);

            if (UserConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveOffer", sessionId, sdpOffer);
                logger.LogDebug("Sent offer to {TargetUserId}", targetUserId);
            }
            else
            {
                logger.LogWarning("Target user {TargetUserId} not connected", targetUserId);
            }
        }

        public async Task SendAnswer(string sessionId, string targetUserId, object sdpAnswer)
        {
            logger.LogDebug("SendAnswer => SessionId={SessionId}, TargetUserId={TargetUserId}", sessionId, targetUserId);

            if (UserConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveAnswer", sessionId, sdpAnswer);
                logger.LogDebug("Sent answer to {TargetUserId}", targetUserId);
            }
        }

        public async Task SendIceCandidate(string sessionId, string targetUserId, object candidate)
        {
            logger.LogDebug("SendIceCandidate => SessionId={SessionId}, TargetUserId={TargetUserId}", sessionId, targetUserId);

            if (UserConnections.TryGetValue(targetUserId, out var targetConn))
            {
                await Clients.Client(targetConn).SendAsync("ReceiveIceCandidate", sessionId, candidate);
            }
        }
    }
}