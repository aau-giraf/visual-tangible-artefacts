using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests
{
    public class UsersControllerTests : IClassFixture<CustomApplicationFactory>
    {
        private readonly HttpClient _client;
        private readonly Utilities _utilities;

        public UsersControllerTests(CustomApplicationFactory factory)
        {
            _client = factory.CreateClient();
            _utilities = new Utilities(_client);
        }

        [Fact]
        public async Task TestUserSignUp()
        {
            var result = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");
            Assert.NotNull(result?.Token);
        }

        [Fact]
        public async Task TestUserLogin()
        {
            await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");
            var result = await _utilities.LoginUserAsync("testuser", "testpassword");
            Assert.NotNull(result?.Token);
        }

        [Fact]
        public async Task TestUserDeletion()
        {
            var signUpResult = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");
            Assert.NotNull(signUpResult?.Token);

            var loginResult = await _utilities.LoginUserAsync("testuser", "testpassword");
            Assert.NotNull(loginResult?.Token);

            await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            await Assert.ThrowsAsync<HttpRequestException>(async () => await _utilities.LoginUserAsync("testuser", "testpassword"));
        }
    }
}
