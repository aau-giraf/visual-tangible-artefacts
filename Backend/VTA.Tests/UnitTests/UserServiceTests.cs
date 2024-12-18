using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.UnitTests
{
    public class UserServiceTests : IClassFixture<CustomApplicationFactory>
    {
        private readonly HttpClient _client;
        private readonly Utilities _utilities;

        public UserServiceTests(CustomApplicationFactory factory)
        {
            _client = factory.CreateClient();
            _utilities = new Utilities(_client);
        }

        [Fact]
        public async Task CreateUser_ShouldReturnUserGetDTO()
        {
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task GetUserById_ShouldReturnUserGetDTO()
        {
            var username = _utilities.GenerateUniqueUsername();
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);

            var response = await _client.SendAsync(request);
            response.EnsureSuccessStatusCode(); // Ensure the response status code is successful

            var user = await response.Content.ReadFromJsonAsync<UserGetDTO>();

            Assert.NotNull(user);
            Assert.Equal(signUpResult.userId, user!.Id);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task DeleteUser_ShouldReturnNoContent()
        {
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync("testuser", "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult!.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }
    }
}