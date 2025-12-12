using System.Net;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.BasicTests;

public class ProgramTests : IClassFixture<CustomApplicationFactory>
{
    // Inshallah we remove this one day
    private readonly CustomApplicationFactory _factory;

    public ProgramTests(CustomApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_EndpointsReturnSuccess()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/swagger/index.html");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
