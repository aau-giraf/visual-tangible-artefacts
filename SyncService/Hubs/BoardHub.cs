using Microsoft.AspNetCore.SignalR;

namespace SyncService.Hubs
{
    public class BoardHub : Hub
    {
        private static Dictionary<string, string> userConnections = new();  // userId -> connectionId
        private static Dictionary<string, string> activeSessions = new();   // sessionId -> userId pair
        private static Dictionary<string, BoardSession> boardSessions = new();

        public class BoardSession
        {
            public string SessionId { get; set; }
            public string User1Id { get; set; }
            public string User2Id { get; set; }
            public List<string> Connections { get; set; } = new();
        }

        // User registers their connection
        public async Task RegisterUser(string userId)
        {
            userConnections[userId] = Context.ConnectionId;
            await Clients.All.SendAsync("UserOnline", userId);
        }

        // User A sends a session request to User B
        public async Task RequestSession(string fromUserId, string toUserId)
        {
            if (userConnections.TryGetValue(toUserId, out var toConnectionId))
            {
                await Clients.Client(toConnectionId).SendAsync("SessionRequested", fromUserId);
            }
            else
            {
                await Clients.Caller.SendAsync("UserOffline", toUserId);
            }
        }

        // User B accepts the request and they both join the session
        public async Task AcceptSession(string sessionId, string fromUserId, string toUserId)
        {
            var session = new BoardSession
            {
                SessionId = sessionId,
                User1Id = fromUserId,
                User2Id = toUserId
            };

            boardSessions[sessionId] = session;

            // Add both users to the session group
            if (userConnections.TryGetValue(fromUserId, out var fromConnectionId))
            {
                await Groups.AddToGroupAsync(fromConnectionId, sessionId);
                session.Connections.Add(fromConnectionId);
            }

            if (userConnections.TryGetValue(toUserId, out var toConnectionId))
            {
                await Groups.AddToGroupAsync(toConnectionId, sessionId);
                session.Connections.Add(toConnectionId);
            }

            // Notify both that session started
            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId);
        }

        // Reject the request
        public async Task RejectSession(string fromUserId)
        {
            if (userConnections.TryGetValue(fromUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("SessionRejected");
            }
        }

        // During active session: sync board updates
        public async Task UpdateBoard(string sessionId, object boardData)
        {
            await Clients.Group(sessionId).SendAsync("BoardUpdated", boardData);
        }

        // End session
        public async Task EndSession(string sessionId)
        {
            await Clients.Group(sessionId).SendAsync("SessionEnded");
            boardSessions.Remove(sessionId);
        }

        public override async Task OnDisconnectedAsync(Exception exception)
        {
            var userToRemove = userConnections.FirstOrDefault(x => x.Value == Context.ConnectionId).Key;
            if (userToRemove != null)
            {
                userConnections.Remove(userToRemove);
                await Clients.All.SendAsync("UserOffline", userToRemove);
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}