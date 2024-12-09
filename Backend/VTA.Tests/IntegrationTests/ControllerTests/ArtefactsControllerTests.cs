using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Runtime.CompilerServices;
using System.Text.Json;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class ArtefactsControllerTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    
    private readonly Utilities _utilities;

    //private readonly ArtefactContext _context;

    public ArtefactsControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        //var _context = factory.Services.GetRequiredService<ArtefactContext>();
        _utilities = new Utilities(_client);
    }


    [Fact]
    public async Task TestAddArtefact()
    {
        var loginData = await _utilities.CreateUserAndReturnLoginDataAsync();

        var content = new MultipartFormDataContent();

        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        content.Add(imageContent, "Image");
        content.Add(new StringContent(loginData.userId), "UserId");

        var request = new HttpRequestMessage(HttpMethod.Post, "api/Artefacts") 
        { 
            Content = content 
        };

        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        ArtefactGetDTO? artefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(await response.Content.ReadAsStreamAsync());
        Assert.NotNull(artefact);

        var getArtefactResponse = await _client.GetAsync($"/api/Artefacts/{artefact.ArtefactId}");
        Assert.Equal(HttpStatusCode.OK, getArtefactResponse.StatusCode);

        var retrievedArtefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(await getArtefactResponse.Content.ReadAsStreamAsync());
        Assert.NotNull(retrievedArtefact);
        Assert.Equal(artefact.ArtefactId, retrievedArtefact.ArtefactId);
        Assert.Equal(loginData.userId, retrievedArtefact.UserId);

        Assert.True(File.Exists($"/api/Assets/Artefact/{artefact.ArtefactId}"));

        await _utilities.DeleteUserWithTokenAsync();
    }
}
