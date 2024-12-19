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
            var username = _utilities.GenerateUniqueUsername();
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");

            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task TestUserLogin()
        {
            var username = _utilities.GenerateUniqueUsername();
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var (loginStatus, loginResult) = await _utilities.LoginUserAsync(username, "testpassword");

            Assert.Equal(HttpStatusCode.OK, loginStatus);
            Assert.NotNull(loginResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task TestUserDeletion()
        {
            var username = _utilities.GenerateUniqueUsername();
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var (loginStatus, loginResult) = await _utilities.LoginUserAsync(username, "testpassword");
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
            var username = _utilities.GenerateUniqueUsername();
            // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "correctpassword", "Test User");
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
            // Arrange
            var username1 = _utilities.GenerateUniqueUsername();
            var username2 = _utilities.GenerateUniqueUsername();

            // Act
            // User One Signup
            var (signUpStatus1, signUpResult1) = await _utilities.SignUpUserAsync(username1, "password1", "User One");
            var (signUpStatus2, signUpResult2) = await _utilities.SignUpUserAsync(username2, "password2", "User Two");

            // Assert - Ensure both users signed up successfully
            Assert.Equal(HttpStatusCode.OK, signUpStatus1);
            Assert.NotNull(signUpResult1?.Token);
            Assert.Equal(HttpStatusCode.OK, signUpStatus2);
            Assert.NotNull(signUpResult2?.Token);

            // Act - Unauthorized delete attempt
            var deleteStatusForbidden = await _utilities.DeleteUserAsync(signUpResult1!.userId, signUpResult2!.Token);

            // Act - Authorized deletes
            var deleteStatusUser1 = await _utilities.DeleteUserAsync(signUpResult1.userId, signUpResult1.Token);
            var deleteStatusUser2 = await _utilities.DeleteUserAsync(signUpResult2.userId, signUpResult2.Token);

            // Assert - Verify outcomes
            Assert.Equal(HttpStatusCode.Forbidden, deleteStatusForbidden); // Unauthorized delete attempt
            Assert.Equal(HttpStatusCode.NoContent, deleteStatusUser1);     // Successful delete for User One
            Assert.Equal(HttpStatusCode.NoContent, deleteStatusUser2);     // Successful delete for User Two
        }
    }
}
