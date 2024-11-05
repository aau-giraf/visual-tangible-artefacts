using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Json;
using System.Text;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class UsersControllerTests : IClassFixture<CustomApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly TestUserHelper _testUserHelper;
    private readonly string _secretKey;

    public UsersControllerTests(CustomApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
        _testUserHelper = new TestUserHelper(_client);
        _secretKey = factory.Configuration["Secret:SecretKey"];
    }

    [Fact]
    public async Task Login_ReturnsValidJwtWithCorrectUserId()
    {
        await _testUserHelper.CreateTestUserAsync();
        var loginDto = new UserLoginDTO
        {
            Username = "testuser",
            Password = "123"
        };

        var response = await _client.PostAsJsonAsync("/api/Users/Login", loginDto);
        response.EnsureSuccessStatusCode();

        var loginResponse = await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>();
        Assert.NotNull(loginResponse);
        Assert.NotEmpty(loginResponse.Token);

        await ValidateJwtMatchesUser(loginResponse.Token, loginDto.Username);

        await _testUserHelper.DeleteTestUserAsync();
    }

    private async Task ValidateJwtMatchesUser(string token, string expectedUsername)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_secretKey);

        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = "api.vta.com",
            ValidateAudience = true,
            ValidAudience = "user.vta.com",
            ValidateLifetime = false
        };

        tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
        var jwtToken = (JwtSecurityToken)validatedToken;
        var userId = jwtToken.Claims.First(x => x.Type == "id").Value;

        var requestMessage = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/{userId}");
        requestMessage.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        var userResponse = await _client.SendAsync(requestMessage);
        userResponse.EnsureSuccessStatusCode();
        var user = await userResponse.Content.ReadFromJsonAsync<UserGetDTO>();

        Assert.Equal(expectedUsername, user?.Username);

        Assert.NotNull(jwtToken.Claims.First(x => x.Type == JwtRegisteredClaimNames.Jti));
        Assert.NotNull(jwtToken.Claims.First(x => x.Type == JwtRegisteredClaimNames.Iat));
    }
}
