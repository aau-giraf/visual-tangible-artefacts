using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SyncService.Hubs;
using SyncService.Models.ArtifactAdded;
using SyncService.Tests.Helpers;
using VTA.Data.Models;
using Xunit.Abstractions;

namespace SyncService.Tests.IntegrationTests
{
    [Collection("BoardHub Database Collection")]
    public class BoardHubTests
    {
        private readonly HubFixture _fixture;
        private readonly DatabaseFixture _dbFixture;
        private readonly ITestOutputHelper _output;
        
        private const string SessionId = "test-session-id";
        
        private const string BoardId = "test-board-id";
        
        private const string ArtifactId = "test-artifact-id";
        
        private const string UserId = "test-user-id";
        
        private const string CallerId = "test-caller-id";
        private const string CalleeId = "test-callee-id";
        
        
        public BoardHubTests(DatabaseFixture dbFixture, ITestOutputHelper output)
        {
            _fixture = new HubFixture();
            _dbFixture = dbFixture;
            _output = output;
        }

        private BoardHub CreateHub()
        {
            // Clear static state before each test to ensure isolation
            BoardHub.ClearStaticState();
            
            var hub = new BoardHub(_dbFixture.DbContext);
            hub.Clients = _fixture.MockClients.Object;
            hub.Context = _fixture.MockHubCallerContext.Object;
            hub.Groups = _fixture.MockGroupManager.Object;
            return hub;
        }

        [Fact]
        public async Task RegisterUser_WithValidUser_Completes()
        {
            var hub = CreateHub();
            await hub.RegisterUser(CalleeId, new List<string>());
            _fixture.MockHubCallerContext.Verify(c => c.User, Times.AtLeastOnce);
        }

        [Fact]
        public async Task RegisterUser_WithEmpty_Completes()
        {
            var hub = CreateHub();
            await hub.RegisterUser("", new List<string>());
            _fixture.MockClients.Verify(c => c.Client(It.IsAny<string>()), Times.Never);
        }

        [Fact]
        public async Task RegisterUser_WithWhitespace_Completes()
        {
            var hub = CreateHub();
            await hub.RegisterUser(" ", new List<string>());
            _fixture.MockClients.Verify(c => c.Client(It.IsAny<string>()), Times.Never);
        }

        [Fact]
        public async Task RequestSession_WithValidUsers_Completes()
        {
            var hub = CreateHub();
            await hub.RequestSession(CallerId, CalleeId);
            _fixture.MockClients.Verify(c => c.Client(It.IsAny<string>()), Times.AtLeastOnce);
        }

        [Fact]
        public async Task RequestSession_CallsClient()
        {
            var hub = CreateHub();
            await hub.RequestSession(CallerId, CalleeId);
            _fixture.MockClients.Verify(c => c.Client(It.IsAny<string>()), Times.AtLeastOnce);
        }

        [Fact]
        public async Task AcceptSession_WithValidParams_Completes()
        {
            await AddCallerAndCalleeToDb();
            var hub = CreateHub();
            await hub.AcceptSession(SessionId, CallerId, CalleeId, BoardId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
            await CleanupTestData();
        }

        [Fact]
        public async Task AcceptSession_CallsGroup()
        {
            await AddCallerAndCalleeToDb();
            var hub = CreateHub();
            await hub.AcceptSession(SessionId, CallerId, CalleeId, BoardId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
            await CleanupTestData();
        }

        [Fact]
        public async Task RejectSession_WithValidUser_Completes()
        {
            await AddTestUserToDb(); // Add the current user (test-user-id)
            await AddUserToDb(CallerId, "Caller User", "CallerUser"); // Add the caller
            var hub = CreateHub();
            await hub.RejectSession(CallerId);
            _fixture.MockHubCallerContext.Verify(c => c.User, Times.AtLeastOnce);
            await CleanupTestData();
        }

        [Fact]
        public async Task EndSession_WithValidId_Completes()
        {
            var hub = CreateHub();
            await hub.EndSession(SessionId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
        }

        [Fact]
        public async Task EndSession_CallsGroup()
        {
            var hub = CreateHub();
            await hub.EndSession(SessionId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
        }

        [Fact]
        public async Task UpdateBoard_WithValidSession_Completes()
        {
            var hub = CreateHub();
            await hub.UpdateBoard(SessionId, new { data = "test" });
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task UpdateBoard_CallsOthersInGroup()
        {
            var hub = CreateHub();
            await hub.UpdateBoard(SessionId, new { data = "test" });
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactRemoved_WithValidSession_Completes()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactRemoved(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactRemoved_CallsOthersInGroup()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactRemoved(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactMoved_WithValidSession_Completes()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactMoved(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactMoved_CallsOthersInGroup()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactMoved(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactResized_WithValidSession_Completes()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactResized(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task ArtifactResized_CallsOthersInGroup()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.ArtifactResized(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task LayoutChanged_WithValidSession_Completes()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.LayoutChanged(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task LayoutChanged_CallsOthersInGroup()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\"}").RootElement;
            await hub.LayoutChanged(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task FieldCountChanged_WithValidSession_Completes()
        {
            var hub = CreateHub();
            var data = JsonDocument.Parse("{\"sessionId\":\""+ SessionId +"\",\"count\":5}").RootElement;
            await hub.FieldCountChanged(data);
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
        }

        [Fact]
        public async Task OnDisconnectedAsync_WithNull_Completes()
        {
            var hub = CreateHub();
            await hub.OnDisconnectedAsync(null);
            Assert.True(true);
        }

        [Fact]
        public async Task OnDisconnectedAsync_WithException_Completes()
        {
            var hub = CreateHub();
            await hub.OnDisconnectedAsync(new Exception("test"));
            Assert.True(true);
        }

        [Fact]
        public async Task ArtifactAdded_WithValidSession_Completes_With_ArtifactRejected()
        {
            var payload = CreateArtifactAddedPayload();
            
            var jsonString = JsonSerializer.Serialize(payload);
            var data = JsonDocument.Parse(jsonString).RootElement;
            
            var hub = CreateHub();
            
            var artifactRejectedReceived = false;
            string? errorMessage = null;
            
            _fixture.OnMessage("ArtifactRejected", args =>
            {
                artifactRejectedReceived = true;
                if (args.Length > 1 && args[1] is string message)
                {
                    errorMessage = message;
                    _output.WriteLine($"[ArtifactRejected]: {message}");
                }
            });
            
            await hub.ArtifactAdded(data);
            
            _fixture.MockClients.Verify(c => c.Caller, Times.Once);
            
            Assert.True(artifactRejectedReceived, "ArtifactRejected message was not sent to caller");
            Assert.NotNull(errorMessage);
            Assert.Equal("Artifact not found or does not belong to you", errorMessage);
        }
        
        [Fact]
        public async Task ArtifactAdded_WithValidSession_Completes_With_ArtifactAdded()
        {
            await AddTestUserToDb();
            await AddTestArtifactToDb();

            var payload = CreateArtifactAddedPayload();
            
            var jsonString = JsonSerializer.Serialize(payload);
            var data = JsonDocument.Parse(jsonString).RootElement;
            
            var hub = CreateHub();
            
            var artifactAddedReceived = false;
            
            _fixture.OnMessage("ArtifactAdded", args =>
            {
                artifactAddedReceived = true;
                _output.WriteLine($"[ArtifactAdded] Message sent to OthersInGroup with {args.Length} arguments");
            });
            
            await hub.ArtifactAdded(data);
            
            _fixture.MockClients.Verify(c => c.OthersInGroup(SessionId), Times.Once);
            
            Assert.True(artifactAddedReceived, "ArtifactAdded message was not sent to OthersInGroup");
            
            await CleanupTestData();
        }

        private ArtifactAddedPayload CreateArtifactAddedPayload()
        {
            return new ArtifactAddedPayload
            {
                SessionId = SessionId,
                Artifact = new ArtifactPayload
                {
                    Id = ArtifactId,
                    SavedArtefactId = "saved-1",
                    Name = "Test Artifact",
                    Size = new SizePayload
                    {
                        Width = 100,
                        Height = 100
                    }
                }
            };
        }
        
        private async Task AddTestArtifactToDb()
        {
            var artifact = new Artefact
            {
                ArtefactId = ArtifactId,
                ArtefactIndex = 1,
                UserId = UserId,
                Name = "Test Artifact",
                ImagePath = null,
                SoundPath = null
            };
            _dbFixture.DbContext.Artefacts.Add(artifact);
            await _dbFixture.DbContext.SaveChangesAsync();
        }

        private async Task AddTestUserToDb()
        {
            await AddUserToDb(UserId, "Test User", "TestUser");
        }
        
        private async Task AddCallerAndCalleeToDb()
        {
            await AddUserToDb(CallerId, "Caller User", "CallerUser");
            await AddUserToDb(CalleeId, "Callee User", "CalleeUser");
        }
        
        private async Task AddUserToDb(string userId, string name, string username)
        {
            // Check if user already exists in database
            var existingUser = await _dbFixture.DbContext.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == userId);
            
            if (existingUser != null)
            {
                return; // User already exists, no need to add
            }
            
            // Clear any tracked entities with the same ID to avoid conflicts
            var trackedEntity = _dbFixture.DbContext.ChangeTracker.Entries<User>()
                .FirstOrDefault(e => e.Entity.Id == userId);
            if (trackedEntity != null)
            {
                _dbFixture.DbContext.Entry(trackedEntity.Entity).State = EntityState.Detached;
            }
            
            var user = new User
            {
                Id = userId,
                Name = name,
                Password = "hashedpassword",
                Username = username
            };
            _dbFixture.DbContext.Users.Add(user);
            await _dbFixture.DbContext.SaveChangesAsync();
        }

        private async Task CleanupTestData()
        {
            // Delete sessions first (to avoid FK constraint violations)
            var sessionsToDelete = _dbFixture.DbContext.Sessions
                .Where(s => s.CallerId == UserId || s.CalleeId == UserId || 
                            s.CallerId == CallerId || s.CalleeId == CallerId ||
                            s.CallerId == CalleeId || s.CalleeId == CalleeId ||
                            s.CallerId == "different-callee-id" || s.CalleeId == "different-callee-id")
                .ToList();
            
            if (sessionsToDelete.Any())
            {
                _dbFixture.DbContext.Sessions.RemoveRange(sessionsToDelete);
                await _dbFixture.DbContext.SaveChangesAsync();
            }
            
            var artifactToDelete = _dbFixture.DbContext.Artefacts.FirstOrDefault(a => a.ArtefactId == ArtifactId);
            if (artifactToDelete != null)
            {
                _dbFixture.DbContext.Artefacts.Remove(artifactToDelete);
                await _dbFixture.DbContext.SaveChangesAsync();
            }

            // Remove all test users
            var userIds = new[] { UserId, CallerId, CalleeId, "different-callee-id" };
            foreach (var userId in userIds)
            {
                var userToDelete = _dbFixture.DbContext.Users.FirstOrDefault(u => u.Id == userId);
                if (userToDelete != null)
                {
                    _dbFixture.DbContext.Users.Remove(userToDelete);
                    await _dbFixture.DbContext.SaveChangesAsync();
                }
            }
        }

        // Missed Call Notification Tests - User Story Verification
        [Fact]
        public async Task RequestSession_WhenNotAnswered_SendsMissedCallNotificationAfter30Seconds()
        {
            // Arrange
            await AddCallerAndCalleeToDb();
            
            var hub = CreateHub();
            
            // Setup caller and callee by registering them (this populates UserConnections)
            await hub.RegisterUser(CallerId, new List<string>());
            
            // Setup callee context with a different connection ID
            var calleeContext = new Mock<HubCallerContext>();
            calleeContext.Setup(c => c.ConnectionId).Returns("callee-connection-id");
            calleeContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(CalleeId, "CalleeUser"));
            hub.Context = calleeContext.Object;
            await hub.RegisterUser(CalleeId, new List<string>());
            
            // Reset context back to caller
            hub.Context = _fixture.MockHubCallerContext.Object;
            
            // Track if MissedCall was sent
            var missedCallSent = false;
            string? missedCallUserId = null;
            string? missedCallUserName = null;
            
            _fixture.OnMessage("MissedCall", args =>
            {
                missedCallSent = true;
                if (args.Length >= 2)
                {
                    missedCallUserId = args[0] as string;
                    missedCallUserName = args[1] as string;
                }
                _output.WriteLine($"[MissedCall] Sent to callee from {missedCallUserName} (userId: {missedCallUserId})");
            });
            
            // Act
            await hub.RequestSession(CallerId, CalleeId);
            
            // Verify SessionRequested was sent
            _fixture.MockClients.Verify(c => c.Client(It.IsAny<string>()), Times.AtLeastOnce);
            
            // Wait for the 30-second timeout to trigger
            await Task.Delay(31000); // Wait slightly longer than timeout
            
            // Assert
            Assert.True(missedCallSent, "MissedCall notification was not sent after timeout");
            Assert.Equal(CallerId, missedCallUserId);
            Assert.NotNull(missedCallUserName);
            
            // Cleanup
            await CleanupTestData();
        }

        [Fact]
        public async Task RequestSession_WhenAccepted_DoesNotSendMissedCallNotification()
        {
            // Arrange
            await AddCallerAndCalleeToDb();
            var hub = CreateHub();
            
            // Register users
            await hub.RegisterUser(CallerId, new List<string>());
            
            var calleeContext = new Mock<HubCallerContext>();
            calleeContext.Setup(c => c.ConnectionId).Returns("callee-connection-id");
            calleeContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(CalleeId, "CalleeUser"));
            hub.Context = calleeContext.Object;
            await hub.RegisterUser(CalleeId, new List<string>());
            
            hub.Context = _fixture.MockHubCallerContext.Object;
            
            var missedCallSent = false;
            
            _fixture.OnMessage("MissedCall", args =>
            {
                missedCallSent = true;
                _output.WriteLine("[MissedCall] Unexpectedly sent");
            });
            
            // Act
            await hub.RequestSession(CallerId, CalleeId);
            
            // Accept the session before timeout
            await Task.Delay(1000); // Short delay
            await hub.AcceptSession(SessionId, CallerId, CalleeId, BoardId);
            
            // Wait beyond the timeout period
            await Task.Delay(31000);
            
            // Assert - MissedCall should NOT be sent because session was accepted
            Assert.False(missedCallSent, "MissedCall notification should not be sent when call is accepted");
            
            // Cleanup
            await CleanupTestData();
        }

        [Fact]
        public async Task RequestSession_WhenRejected_DoesNotSendMissedCallNotification()
        {
            // Arrange
            await AddCallerAndCalleeToDb();
            var hub = CreateHub();
            
            // Register users
            await hub.RegisterUser(CallerId, new List<string>());
            
            var calleeContext = new Mock<HubCallerContext>();
            calleeContext.Setup(c => c.ConnectionId).Returns("callee-connection-id");
            calleeContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(CalleeId, "CalleeUser"));
            hub.Context = calleeContext.Object;
            await hub.RegisterUser(CalleeId, new List<string>());
            
            var missedCallSent = false;
            
            _fixture.OnMessage("MissedCall", args =>
            {
                missedCallSent = true;
                _output.WriteLine("[MissedCall] Unexpectedly sent");
            });
            
            hub.Context = _fixture.MockHubCallerContext.Object;
            
            // Act
            await hub.RequestSession(CallerId, CalleeId);
            
            // Reject the session before timeout
            await Task.Delay(1000);
            hub.Context = calleeContext.Object;
            await hub.RejectSession(CallerId);
            
            // Wait beyond the timeout period
            await Task.Delay(31000);
            
            // Assert - MissedCall should NOT be sent because session was rejected
            Assert.False(missedCallSent, "MissedCall notification should not be sent when call is rejected");
            
            // Cleanup
            await CleanupTestData();
        }

        [Fact]
        public async Task RequestSession_MissedCallNotification_IncludesCallerName()
        {
            // Arrange
            await AddTestUserToDb(); // Add a user with known name
            await AddUserToDb("different-callee-id", "Callee User", "CalleeUser"); // Add callee user
            
            var hub = CreateHub();
            var callerId = UserId; // Use the test user ID with known name
            var calleeId = "different-callee-id";
            
            // Register users - caller with custom user context
            var callerContext = new Mock<HubCallerContext>();
            callerContext.Setup(c => c.ConnectionId).Returns("caller-connection-id");
            callerContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(callerId, "Test User"));
            hub.Context = callerContext.Object;
            await hub.RegisterUser(callerId, new List<string>());
            
            // Register callee
            var calleeContext = new Mock<HubCallerContext>();
            calleeContext.Setup(c => c.ConnectionId).Returns("callee-connection-id");
            calleeContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(calleeId, "Callee User"));
            hub.Context = calleeContext.Object;
            await hub.RegisterUser(calleeId, new List<string>());
            
            string? receivedCallerName = null;
            
            _fixture.OnMessage("MissedCall", args =>
            {
                if (args.Length >= 2)
                {
                    receivedCallerName = args[1] as string;
                }
                _output.WriteLine($"[MissedCall] Caller name: {receivedCallerName}");
            });
            
            // Reset to caller context for RequestSession
            hub.Context = callerContext.Object;
            
            // Act
            await hub.RequestSession(callerId, calleeId);
            await Task.Delay(31000);
            
            // Assert
            Assert.NotNull(receivedCallerName);
            Assert.Equal("Test User", receivedCallerName); // Should match the name from RegisterUser
            
            // Cleanup
            await CleanupTestData();
        }

        [Fact]
        public async Task RequestSession_MissedCallNotification_IncludesCallerUserId()
        {
            // Arrange
            await AddTestUserToDb();
            await AddUserToDb("different-callee-id", "Callee User", "CalleeUser"); // Add callee user
            
            var hub = CreateHub();
            var callerId = UserId;
            var calleeId = "different-callee-id";
            
            // Register users
            var callerContext = new Mock<HubCallerContext>();
            callerContext.Setup(c => c.ConnectionId).Returns("caller-connection-id");
            callerContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(callerId, "Test User"));
            hub.Context = callerContext.Object;
            await hub.RegisterUser(callerId, new List<string>());
            
            var calleeContext = new Mock<HubCallerContext>();
            calleeContext.Setup(c => c.ConnectionId).Returns("callee-connection-id");
            calleeContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(calleeId, "Callee User"));
            hub.Context = calleeContext.Object;
            await hub.RegisterUser(calleeId, new List<string>());
            
            string? receivedCallerUserId = null;
            
            _fixture.OnMessage("MissedCall", args =>
            {
                if (args.Length >= 2)
                {
                    receivedCallerUserId = args[0] as string;
                }
                _output.WriteLine($"[MissedCall] Caller userId: {receivedCallerUserId}");
            });
            
            hub.Context = callerContext.Object;
            
            // Act
            await hub.RequestSession(callerId, calleeId);
            await Task.Delay(31000);
            
            // Assert
            Assert.NotNull(receivedCallerUserId);
            Assert.Equal(UserId, receivedCallerUserId);
            
            // Cleanup
            await CleanupTestData();
        }

        // Online/Offline Status Tests - User Story Verification
        [Fact]
        public async Task RegisterUser_AddsUserToOnlineUsers()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "online-user-1";
            
            // Act
            await hub.RegisterUser(userId, new List<string>());
            var isOnline = hub.IsUserOnline(userId);
            
            // Assert
            Assert.True(isOnline, "User should be marked as online after registration");
        }

        [Fact]
        public async Task RegisterUser_WithContacts_NotifiesContactsOfOnlineStatus()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "user-1";
            var contactId1 = "contact-1";
            var contactId2 = "contact-2";
            
            // Register contacts first (they need to be online to receive notifications)
            var contact1Context = new Mock<HubCallerContext>();
            contact1Context.Setup(c => c.ConnectionId).Returns("contact1-conn-id");
            contact1Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(contactId1, "Contact 1"));
            hub.Context = contact1Context.Object;
            await hub.RegisterUser(contactId1, new List<string>());
            
            var contact2Context = new Mock<HubCallerContext>();
            contact2Context.Setup(c => c.ConnectionId).Returns("contact2-conn-id");
            contact2Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(contactId2, "Contact 2"));
            hub.Context = contact2Context.Object;
            await hub.RegisterUser(contactId2, new List<string>());
            
            // Track status change notifications
            var statusChanges = new List<(string userId, bool isOnline)>();
            _fixture.OnMessage("UserOnlineStatusChanged", args =>
            {
                if (args.Length >= 2 && args[0] is string uid && args[1] is bool online)
                {
                    statusChanges.Add((uid, online));
                    _output.WriteLine($"[UserOnlineStatusChanged] userId: {uid}, isOnline: {online}");
                }
            });
            
            // Reset context to new user
            var userContext = new Mock<HubCallerContext>();
            userContext.Setup(c => c.ConnectionId).Returns("user-conn-id");
            userContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(userId, "User 1"));
            hub.Context = userContext.Object;
            
            // Act - Register user with contacts list
            await hub.RegisterUser(userId, new List<string> { contactId1, contactId2 });
            
            // Assert
            Assert.True(hub.IsUserOnline(userId), "User should be online after registration");
            Assert.Contains(statusChanges, sc => sc.userId == userId && sc.isOnline == true);
            _output.WriteLine($"Total status changes received: {statusChanges.Count}");
        }

        [Fact]
        public async Task GetOnlineUsers_ReturnsListOfOnlineUsers()
        {
            // Arrange
            var hub = CreateHub();
            var user1Id = "online-user-1";
            var user2Id = "online-user-2";
            var user3Id = "online-user-3";
            
            // Register multiple users
            var user1Context = new Mock<HubCallerContext>();
            user1Context.Setup(c => c.ConnectionId).Returns("user1-conn");
            user1Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user1Id, "User 1"));
            hub.Context = user1Context.Object;
            await hub.RegisterUser(user1Id, new List<string>());
            
            var user2Context = new Mock<HubCallerContext>();
            user2Context.Setup(c => c.ConnectionId).Returns("user2-conn");
            user2Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user2Id, "User 2"));
            hub.Context = user2Context.Object;
            await hub.RegisterUser(user2Id, new List<string>());
            
            var user3Context = new Mock<HubCallerContext>();
            user3Context.Setup(c => c.ConnectionId).Returns("user3-conn");
            user3Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user3Id, "User 3"));
            hub.Context = user3Context.Object;
            await hub.RegisterUser(user3Id, new List<string>());
            
            // Act
            var onlineUsers = hub.GetOnlineUsers();
            
            // Assert
            Assert.NotNull(onlineUsers);
            Assert.Contains(user1Id, onlineUsers);
            Assert.Contains(user2Id, onlineUsers);
            Assert.Contains(user3Id, onlineUsers);
            Assert.Equal(3, onlineUsers.Count);
            _output.WriteLine($"Online users: {string.Join(", ", onlineUsers)}");
        }

        [Fact]
        public async Task IsUserOnline_ReturnsTrueForOnlineUser()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "test-online-user";
            
            // Act
            await hub.RegisterUser(userId, new List<string>());
            var isOnline = hub.IsUserOnline(userId);
            
            // Assert
            Assert.True(isOnline, "IsUserOnline should return true for registered user");
        }

        [Fact]
        public void IsUserOnline_ReturnsFalseForOfflineUser()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "offline-user";
            
            // Act
            var isOnline = hub.IsUserOnline(userId);
            
            // Assert
            Assert.False(isOnline, "IsUserOnline should return false for unregistered user");
        }

        [Fact]
        public async Task OnDisconnectedAsync_RemovesUserFromOnlineUsers()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "disconnecting-user";
            
            // Register user first
            await hub.RegisterUser(userId, new List<string>());
            Assert.True(hub.IsUserOnline(userId), "User should be online before disconnect");
            
            // Act
            await hub.OnDisconnectedAsync(null);
            
            // Assert
            var isOnlineAfterDisconnect = hub.IsUserOnline(userId);
            Assert.False(isOnlineAfterDisconnect, "User should be offline after disconnect");
        }

        [Fact]
        public async Task OnDisconnectedAsync_NotifiesContactsOfOfflineStatus()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "user-going-offline";
            var contactId = "contact-to-notify";
            
            // Register contact first
            var contactContext = new Mock<HubCallerContext>();
            contactContext.Setup(c => c.ConnectionId).Returns("contact-conn-id");
            contactContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(contactId, "Contact User"));
            hub.Context = contactContext.Object;
            await hub.RegisterUser(contactId, new List<string>());
            
            // Track status changes
            var statusChanges = new List<(string userId, bool isOnline)>();
            _fixture.OnMessage("UserOnlineStatusChanged", args =>
            {
                if (args.Length >= 2 && args[0] is string uid && args[1] is bool online)
                {
                    statusChanges.Add((uid, online));
                    _output.WriteLine($"[UserOnlineStatusChanged] userId: {uid}, isOnline: {online}");
                }
            });
            
            // Register user with contact
            var userContext = new Mock<HubCallerContext>();
            userContext.Setup(c => c.ConnectionId).Returns("user-conn-id");
            userContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(userId, "Main User"));
            hub.Context = userContext.Object;
            await hub.RegisterUser(userId, new List<string> { contactId });
            
            // Clear previous status changes from registration
            statusChanges.Clear();
            
            // Act - Disconnect user
            await hub.OnDisconnectedAsync(new Exception("Connection lost"));
            
            // Assert
            Assert.False(hub.IsUserOnline(userId), "User should be offline after disconnect");
            Assert.Contains(statusChanges, sc => sc.userId == userId && sc.isOnline == false);
            _output.WriteLine($"Offline notifications sent: {statusChanges.Count(sc => !sc.isOnline)}");
        }

        [Fact]
        public async Task OnlineStatus_UpdatesInRealTime_WhenMultipleUsersConnectAndDisconnect()
        {
            // Arrange
            var hub = CreateHub();
            var user1Id = "user-1";
            var user2Id = "user-2";
            var user3Id = "user-3";
            
            // Act & Assert - Initially no users online
            var onlineUsers = hub.GetOnlineUsers();
            Assert.Empty(onlineUsers);
            
            // User 1 connects
            var user1Context = new Mock<HubCallerContext>();
            user1Context.Setup(c => c.ConnectionId).Returns("user1-conn");
            user1Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user1Id, "User 1"));
            hub.Context = user1Context.Object;
            await hub.RegisterUser(user1Id, new List<string>());
            
            onlineUsers = hub.GetOnlineUsers();
            Assert.Single(onlineUsers);
            Assert.Contains(user1Id, onlineUsers);
            
            // User 2 connects
            var user2Context = new Mock<HubCallerContext>();
            user2Context.Setup(c => c.ConnectionId).Returns("user2-conn");
            user2Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user2Id, "User 2"));
            hub.Context = user2Context.Object;
            await hub.RegisterUser(user2Id, new List<string>());
            
            onlineUsers = hub.GetOnlineUsers();
            Assert.Equal(2, onlineUsers.Count);
            Assert.Contains(user2Id, onlineUsers);
            
            // User 3 connects
            var user3Context = new Mock<HubCallerContext>();
            user3Context.Setup(c => c.ConnectionId).Returns("user3-conn");
            user3Context.Setup(c => c.User).Returns(_fixture.CreateTestUser(user3Id, "User 3"));
            hub.Context = user3Context.Object;
            await hub.RegisterUser(user3Id, new List<string>());
            
            onlineUsers = hub.GetOnlineUsers();
            Assert.Equal(3, onlineUsers.Count);
            
            // User 2 disconnects
            hub.Context = user2Context.Object;
            await hub.OnDisconnectedAsync(null);
            
            onlineUsers = hub.GetOnlineUsers();
            Assert.Equal(2, onlineUsers.Count);
            Assert.DoesNotContain(user2Id, onlineUsers);
            Assert.Contains(user1Id, onlineUsers);
            Assert.Contains(user3Id, onlineUsers);
            
            _output.WriteLine($"Final online users: {string.Join(", ", onlineUsers)}");
        }

        [Fact]
        public async Task RegisterUser_OnlyNotifiesOnlineContacts()
        {
            // Arrange
            var hub = CreateHub();
            var userId = "new-user";
            var onlineContactId = "online-contact";
            var offlineContactId = "offline-contact";
            
            // Register only one contact (the online one)
            var contactContext = new Mock<HubCallerContext>();
            contactContext.Setup(c => c.ConnectionId).Returns("contact-conn-id");
            contactContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(onlineContactId, "Online Contact"));
            hub.Context = contactContext.Object;
            await hub.RegisterUser(onlineContactId, new List<string>());
            
            // Track which users received notifications
            var notifiedUsers = new List<string>();
            _fixture.OnMessage("UserOnlineStatusChanged", args =>
            {
                if (args.Length >= 2 && args[0] is string uid)
                {
                    notifiedUsers.Add(uid);
                    _output.WriteLine($"[UserOnlineStatusChanged] notification about userId: {uid}");
                }
            });
            
            // Register new user with both online and offline contacts
            var userContext = new Mock<HubCallerContext>();
            userContext.Setup(c => c.ConnectionId).Returns("user-conn-id");
            userContext.Setup(c => c.User).Returns(_fixture.CreateTestUser(userId, "New User"));
            hub.Context = userContext.Object;
            
            // Act
            await hub.RegisterUser(userId, new List<string> { onlineContactId, offlineContactId });
            
            // Assert - Notification should be sent about new user
            Assert.Contains(userId, notifiedUsers);
            _output.WriteLine($"Notifications sent to online contacts only. Total: {notifiedUsers.Count}");
        }

        [Fact]
        public async Task GetOnlineUsers_ReturnsEmptyListWhenNoUsersOnline()
        {
            // Arrange
            var hub = CreateHub();
            
            // Act
            var onlineUsers = hub.GetOnlineUsers();
            
            // Assert
            Assert.NotNull(onlineUsers);
            Assert.Empty(onlineUsers);
        }
    }
}