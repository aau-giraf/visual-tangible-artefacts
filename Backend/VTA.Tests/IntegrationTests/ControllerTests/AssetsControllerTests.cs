using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using VTA.Tests.TestHelpers;
using Xunit;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class AssetsControllerTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;

    public AssetsControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetImage_ReturnsNotFound_WhenImageDoesNotExist()
    {
        var filepath = "DrinkImages/nonexistent.jpg";

        var response = await _client.GetAsync($"/api/Assets/{filepath}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}