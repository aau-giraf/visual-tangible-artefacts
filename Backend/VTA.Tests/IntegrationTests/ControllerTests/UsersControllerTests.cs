using System.Net;
using System.Net.Http.Headers;
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

        // This test requires the username to be unique
        // [Fact]
        // public async Task TestDuplicateUserSignUpReturnsConflict()
        // {
        //     // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
        //     var (firstSignUpStatus, _) = await _utilities.SignUpUserAsync("duplicateUser", "testpassword", "Test User");
        //     Assert.Equal(HttpStatusCode.OK, firstSignUpStatus);

        //     var (duplicateSignUpStatus, _) = await _utilities.SignUpUserAsync("duplicateUser", "testpassword", "Test User");
        //     Assert.Equal(HttpStatusCode.Conflict, duplicateSignUpStatus);

        //     var (loginStatus, loginResult) = await _utilities.LoginUserAsync("duplicateUser", "testpassword");
        //     Assert.Equal(HttpStatusCode.OK, loginStatus);

        //     var deleteStatus = await _utilities.DeleteUserAsync(loginResult!.userId, loginResult.Token);
        //     Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        // }

        [Fact]
        public async Task TestLoginWithIncorrectPasswordReturnsNotFound()
        {
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "correctpassword", "Test User");
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var (loginStatus, loginResult) = await _utilities.LoginUserAsync("testuser", "wrongpassword");
            Assert.Equal(HttpStatusCode.NotFound, loginStatus);
            Assert.Null(loginResult);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task TestGetUsersReturnsOk()
        {
            var token = await _utilities.CreateUserAndReturnTokenAsync();

            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Users");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var response = await _client.SendAsync(request);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            await _utilities.DeleteUserWithTokenAsync();
        }

        [Fact]
        public async Task TestGetUsersReturnsUnauthorizedWithNoToken()
        {
            var response = await _client.GetAsync("/api/Users");
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }

        [Fact]
        public async Task TestForbiddenUserDeletionByAnotherUser()
        {
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus1, signUpResult1) = await _utilities.SignUpUserAsync("user1", "password1", "User One");
            Assert.Equal(HttpStatusCode.OK, signUpStatus1);
            Assert.NotNull(signUpResult1?.Token);

            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus2, signUpResult2) = await _utilities.SignUpUserAsync("user2", "password2", "User Two");
            Assert.Equal(HttpStatusCode.OK, signUpStatus2);
            Assert.NotNull(signUpResult2?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult1!.userId, signUpResult2!.Token);
            Assert.Equal(HttpStatusCode.Forbidden, deleteStatus);

            var deleteStatus1 = await _utilities.DeleteUserAsync(signUpResult1!.userId, signUpResult1.Token);
            var deleteStatus2 = await _utilities.DeleteUserAsync(signUpResult2!.userId, signUpResult2.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus1);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus2);
        }

    }
}
