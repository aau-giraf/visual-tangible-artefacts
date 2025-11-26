// SyncService/Hubs/BoardHub.cs

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SyncService.Hubs
{
    [Authorize]
    public class BoardHub : Hub
    {
        private static readonly Dictionary<string, string> userConnections = new(); // userId -> connectionId
        private static readonly Dictionary<string, BoardSession> boardSessions = new(); // sessionId -> session

        public class BoardSession
        {
            public required string SessionId { get; init; }
            public required string User1Id { get; init; }
            public required string User2Id { get; init; }
            public required string BoardId { get; init; }
            public HashSet<string> Connections { get; set; } = new();
        }

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

            // Broadcast to BOTH users in the group
            await Clients.Group(sessionId).SendAsync("SessionStarted", sessionId, boardId);
            Console.WriteLine($"[Hub] Broadcasted SessionStarted to group {sessionId} with boardId={boardId}");
        }

        public async Task RejectSession(string fromUserId)
        {
            Console.WriteLine($"[Hub] RejectSession => {fromUserId}");

            if (userConnections.TryGetValue(fromUserId, out var conn))
                await Clients.Client(conn).SendAsync("SessionRejected");
        }

        public async Task UpdateBoard(string sessionId, object boardData)
        {
            Console.WriteLine($"[Hub] UpdateBoard => sessionId={sessionId}");
            await Clients.Group(sessionId).SendAsync("BoardUpdated", boardData);
            Console.WriteLine($"[Hub] Broadcasted BoardUpdated to group {sessionId}");
        }

        public async Task EndSession(string sessionId)
        {
            Console.WriteLine($"[Hub] EndSession => {sessionId}");
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
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}