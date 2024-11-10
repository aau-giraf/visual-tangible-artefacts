using System.Net;
using System.Net.Http.Json;
using VTA.API.DTOs;
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
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");

            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task TestUserLogin()
        {
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var (loginStatus, loginResult) = await _utilities.LoginUserAsync("testuser", "testpassword");

            Assert.Equal(HttpStatusCode.OK, loginStatus);
            Assert.NotNull(loginResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task TestUserDeletion()
        {
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var (loginStatus, loginResult) = await _utilities.LoginUserAsync("testuser", "testpassword");
            Assert.Equal(HttpStatusCode.OK, loginStatus);
            Assert.NotNull(loginResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);

            var (loginAfterDeletionStatus, loginAfterDeletionResult) = await _utilities.LoginUserAsync("testuser", "testpassword");
            Assert.Equal(HttpStatusCode.NotFound, loginAfterDeletionStatus);
            Assert.Null(loginAfterDeletionResult);
        }
    }
}
