using System.Net.Http.Json;
using VTA.API.DTOs;

namespace VTA.Tests.TestHelpers;

public class TestUserHelper
{
    private readonly HttpClient _client;
    public string? TestUserId { get; private set; }
    private string? _jwtToken;

    public TestUserHelper(HttpClient client)
    {
        _client = client;
    }

    public async Task CreateTestUserAsync()
    {
        var signupDto = new UserSignupDTO
        {
            Username = "testuser",
            Password = "123",
            Name = "Test User"
        };

        var response = await _client.PostAsJsonAsync("/api/Users/SignUp", signupDto);
        response.EnsureSuccessStatusCode();

        var signUpResponse = await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>();
        TestUserId = signUpResponse?.userId;
        _jwtToken = signUpResponse?.Token;
        Assert.NotNull(TestUserId);
        Assert.NotNull(_jwtToken);
    }

    public async Task DeleteTestUserAsync()
    {
        if (TestUserId != null && _jwtToken != null)
        {
            var requestMessage = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/{TestUserId}");
            requestMessage.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _jwtToken);

            var response = await _client.SendAsync(requestMessage);
            response.EnsureSuccessStatusCode();
        }
    }
}
