using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace SyncService.Tests.Helpers
{
    /// <summary>
    /// Base fixture for SignalR Hub tests providing mock context and clients
    /// </summary>
    public class HubFixture
    {
        public Mock<HubCallerContext> MockHubCallerContext { get; set; }
        public Mock<IHubCallerClients> MockClients { get; set; }
        public Mock<IClientProxy> MockClientProxy { get; set; }
        public Mock<ISingleClientProxy> MockSingleClientProxy { get; set; }
        public Mock<IGroupManager> MockGroupManager { get; set; }

        /// <summary>
        /// Event fired when any message is sent through the mock clients
        /// Parameters: (methodName, targetType, args)
        /// </summary>
        public event EventHandler<(string MethodName, string TargetType, object?[] Args)>? MessageSent;

        public HubFixture()
        {
            MockHubCallerContext = new Mock<HubCallerContext>();
            MockClients = new Mock<IHubCallerClients>();
            MockClientProxy = new Mock<IClientProxy>();
            MockSingleClientProxy = new Mock<ISingleClientProxy>();
            MockGroupManager = new Mock<IGroupManager>();

            // Default setup
            MockHubCallerContext.Setup(c => c.ConnectionId).Returns("test-connection-id");
            MockHubCallerContext.Setup(c => c.User).Returns(CreateTestUser());

            // Setup mock returns for all client proxies with callbacks to capture SendCoreAsync calls
            MockClients.Setup(c => c.All).Returns(MockClientProxy.Object);
            MockClients.Setup(c => c.Others).Returns(MockClientProxy.Object);
            MockClients.Setup(c => c.Caller).Returns(MockSingleClientProxy.Object);
            MockClients.Setup(c => c.Client(It.IsAny<string>())).Returns(MockSingleClientProxy.Object);
            MockClients.Setup(c => c.Group(It.IsAny<string>())).Returns(MockClientProxy.Object);
            MockClients.Setup(c => c.OthersInGroup(It.IsAny<string>())).Returns(MockClientProxy.Object);

            // Setup group manager
            MockGroupManager.Setup(g => g.AddToGroupAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            // Setup callbacks to capture messages sent to proxies
            SetupClientProxyCallbacks();
        }

        private void SetupClientProxyCallbacks()
        {
            // Capture calls to MockClientProxy (for broadcasts to All, Others, Group, OthersInGroup)
            MockClientProxy
                .Setup(c => c.SendCoreAsync(It.IsAny<string>(), It.IsAny<object?[]>(), It.IsAny<CancellationToken>()))
                .Callback<string, object?[], CancellationToken>((method, args, _) =>
                {
                    OnMessageSent(method, "ClientProxy", args);
                })
                .Returns(Task.CompletedTask);

            // Capture calls to MockSingleClientProxy (for Caller messages)
            MockSingleClientProxy
                .Setup(c => c.SendCoreAsync(It.IsAny<string>(), It.IsAny<object?[]>(), It.IsAny<CancellationToken>()))
                .Callback<string, object?[], CancellationToken>((method, args, _) =>
                {
                    OnMessageSent(method, "SingleClientProxy", args);
                })
                .Returns(Task.CompletedTask);
        }

        protected virtual void OnMessageSent(string methodName, string targetType, object?[] args)
        {
            MessageSent?.Invoke(this, (methodName, targetType, args));
        }

        public void OnMessage(string methodName, Action<object?[]> handler)
        {
            MessageSent += (sender, e) =>
            {
                if (e.MethodName == methodName)
                {
                    handler(e.Args);
                }
            };
        }

        public ClaimsPrincipal CreateTestUser(string userId = "999", string userName = "TestUser")
        {
            var claims = new List<Claim>
            {
                new Claim("sub", userId),
                new Claim("id", userId),
                new Claim("name", userName),
                new Claim("username", userName)
            };
            var identity = new ClaimsIdentity(claims, "test");
            return new ClaimsPrincipal(identity);
        }
    }
}

