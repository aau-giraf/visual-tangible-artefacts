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
        Assert.NotNull(loginData); // Ensure we have valid login data

        var content = new MultipartFormDataContent();

        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(imageContent, "Image", "testImage.jpg");
        content.Add(new StringContent(loginData.userId), "UserId");
        content.Add(new StringContent("0"), "ArtefactIndex");  // Add missing required field
        content.Add(new StringContent("Test Name"), "Name");   // Optional but good to test

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts") 
        { 
            Content = content
        };

        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Debug the response content
        var responseContent = await response.Content.ReadAsStringAsync();
        Console.WriteLine($"Response Content: {responseContent}");

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        ArtefactGetDTO? artefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await response.Content.ReadAsStreamAsync(),
            options
        );

        var getArtefactRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        getArtefactRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getArtefactResponse = await _client.SendAsync(getArtefactRequest);
        
        Assert.Equal(HttpStatusCode.OK, getArtefactResponse.StatusCode);

        var retrievedArtefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await getArtefactResponse.Content.ReadAsStreamAsync(),
            options
        );
        
        Assert.NotNull(retrievedArtefact);
        Assert.Equal(artefact.ArtefactId, retrievedArtefact.ArtefactId);
        Assert.Equal(loginData.userId, retrievedArtefact.UserId);

        var assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", $"{artefact.ArtefactId}.jpg");
        
        await Task.Delay(1000); // Increased delay for slower systems
        
        Assert.True(File.Exists(assetsPath), $"File not found at: {assetsPath}");

        if (File.Exists(assetsPath))
        {
            File.Delete(assetsPath);
        }

        await _utilities.DeleteUserWithTokenAsync();
    }
}
