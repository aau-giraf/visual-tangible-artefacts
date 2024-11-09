using System.Net;
using System.Net.Http.Json;
using System.Threading.Tasks;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;
using Xunit;

namespace VTA.Tests.IntegrationTests.ControllerTests
{
    public class UsersControllerTests : IClassFixture<CustomApplicationFactory>
    {
        private readonly HttpClient _client;

        public UsersControllerTests(CustomApplicationFactory factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task TestUserSignUp()
        {
            var userDto = new UserSignupDTO
            {
                Username = "testuser",
                Password = "testpassword",
                Name = "Test User"
            };

            var response = await _client.PostAsJsonAsync("/api/Users/SignUp", userDto);

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var result = await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>();
            Assert.NotNull(result?.Token);
        }
    }
}
