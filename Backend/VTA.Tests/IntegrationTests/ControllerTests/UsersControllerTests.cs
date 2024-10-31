using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Xunit;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests
{
    public class UsersControllerTests : IClassFixture<CustomApplicationFactory<Program>>
    {
        private readonly HttpClient _client;

        public UsersControllerTests(CustomApplicationFactory<Program> factory)
        {
            _client = factory.CreateClient();
        }

        // TODO: Needs to be changed when signup dto is done, so we can create a user and delete it right after instead of using a hardcoded user

        [Fact]
        public async Task Login_ReturnsUserWithToken()
        {
            var loginDto = new UserLoginDTO
            {
                Username = "vtatester123",
                Password = "123"
            };

            var response = await _client.PostAsJsonAsync("/api/Users/Login", loginDto);
            response.EnsureSuccessStatusCode();

            var loginResponse = await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>();
            Assert.NotNull(loginResponse);
            Assert.NotEmpty(loginResponse.Token);
            Assert.Equal("596d853e-6bfc-4aa6-9c6b-59a283151805", loginResponse.userId);
        }

        // [Fact]
        // public async Task GetUser_ReturnsUserDetails()
        // {
        //     var userId = "4ecf214f-cb04-47ba-bbcf-c0a36009097b";

        //     var response = await _client.GetAsync($"/api/Users/{userId}");
        //     response.EnsureSuccessStatusCode();

        //     var user = await response.Content.ReadFromJsonAsync<UserGetDTO>();
        //     Assert.NotNull(user);
        //     Assert.Equal(userId, user.Id);
        // }
    }
}
