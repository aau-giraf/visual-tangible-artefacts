// File: VTA.Tests/IntegrationTests/ControllerTests/UsersControllerTests.cs
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using Xunit;

namespace VTA.Tests.IntegrationTests;

public class UsersControllerTests : IClassFixture<CustomWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly IServiceScopeFactory _scopeFactory;

    public UsersControllerTests(CustomWebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
        _scopeFactory = factory.Services.GetRequiredService<IServiceScopeFactory>();
    }

    [Fact]
    public async Task Login_ShouldAuthenticateUser()
    {
        using (var scope = _scopeFactory.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<UserContext>();
            var testUser = new User
            {
                Id = "4ecf214f-cb04-47ba-bbcf-c0a36009097b",
                Username = "vtatester123",
                Password = "123",
                Name = "VTA Tester"
            };

            if (!await context.Users.AnyAsync(u => u.Username == testUser.Username))
            {
                context.Users.Add(testUser);
                await context.SaveChangesAsync();
            }
        }

        var loginDto = new UserLoginDTO
        {
            Username = "vtatester123",
            Password = "123"
        };

        var response = await _client.PostAsJsonAsync("/api/Users/Login", loginDto);

        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>();

        Assert.NotNull(result);
        Assert.NotEmpty(result.Token);
        Assert.Equal("4ecf214f-cb04-47ba-bbcf-c0a36009097b", result.userId);
    }

    [Fact]
    public async Task Login_ShouldReturnNotFound_ForInvalidCredentials()
    {
        var invalidLoginDto = new UserLoginDTO
        {
            Username = "nonexistentuser",
            Password = "WrongPassword!"
        };

        var response = await _client.PostAsJsonAsync("/api/Users/Login", invalidLoginDto);

        Assert.Equal(System.Net.HttpStatusCode.NotFound, response.StatusCode);
    }
}
