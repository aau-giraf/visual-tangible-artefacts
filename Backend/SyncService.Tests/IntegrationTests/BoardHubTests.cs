using System.Text.Json;
using Microsoft.Extensions.Logging;
using Moq;
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
            var mockLogger = new Mock<ILogger<BoardHub>>();
            var hub = new BoardHub(_dbFixture.DbContext, mockLogger.Object);
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
            var hub = CreateHub();
            await hub.AcceptSession(SessionId, CallerId, CalleeId, BoardId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
        }

        [Fact]
        public async Task AcceptSession_CallsGroup()
        {
            var hub = CreateHub();
            await hub.AcceptSession(SessionId, CallerId, CalleeId, BoardId);
            _fixture.MockClients.Verify(c => c.Group(SessionId), Times.Once);
        }

        [Fact]
        public async Task RejectSession_WithValidUser_Completes()
        {
            var hub = CreateHub();
            await hub.RejectSession(CallerId);
            _fixture.MockHubCallerContext.Verify(c => c.User, Times.AtLeastOnce);
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
            var user = new User
            {
                Id = UserId,
                Name = "Test User",
                Password = "hashedpassword",
                Username = "TestUser"
            };
            _dbFixture.DbContext.Users.Add(user);
            await _dbFixture.DbContext.SaveChangesAsync();
        }

        private async Task CleanupTestData()
        {
            var artifactToDelete = _dbFixture.DbContext.Artefacts.FirstOrDefault(a => a.ArtefactId == ArtifactId);
            if (artifactToDelete != null)
            {
                _dbFixture.DbContext.Artefacts.Remove(artifactToDelete);
                await _dbFixture.DbContext.SaveChangesAsync();
            }

            var userToDelete = _dbFixture.DbContext.Users.FirstOrDefault(u => u.Id == UserId);
            if (userToDelete != null)
            {
                _dbFixture.DbContext.Users.Remove(userToDelete);
                await _dbFixture.DbContext.SaveChangesAsync();
            }
        }
    }
}