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

    [Fact]
    public async Task TestGetAllArtefacts()
    {
        var loginData = await _utilities.CreateUserAndReturnLoginDataAsync();
        Assert.NotNull(loginData);

        // Add two test artefacts
        var artefacts = await CreateTestArtefacts(loginData, 2);
        Assert.Equal(2, artefacts.Count);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Artefacts");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var retrievedArtefacts = await JsonSerializer.DeserializeAsync<List<ArtefactGetDTO>>(
            await response.Content.ReadAsStreamAsync(),
            options
        );

        Assert.NotNull(retrievedArtefacts);
        Assert.Equal(2, retrievedArtefacts.Count);

        // Cleanup
        await DeleteTestArtefacts(loginData, artefacts);
        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestUpdateArtefact()
    {
        var loginData = await _utilities.CreateUserAndReturnLoginDataAsync();
        Assert.NotNull(loginData);

        // Create a test artefact
        var artefacts = await CreateTestArtefacts(loginData, 1);
        var artefact = artefacts[0];

        // Update the artefact
        var content = new MultipartFormDataContent
        {
            // var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
            // imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
            // content.Add(imageContent, "Image", "testImage.jpg");
            { new StringContent(loginData.userId), "UserId" },
            { new StringContent("1"), "ArtefactIndex" },  // Changed index
            { new StringContent("Updated Name"), "Name" }
        };

        var request = new HttpRequestMessage(HttpMethod.Put, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        request.Content = content;

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the update
        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        // var getResponse = await _client.SendAsync(getRequest);
        var getResponse = await _client.PutAsJsonAsync($"/api/Users/Artefacts/{artefact.ArtefactId}", artefact);

        
        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var updatedArtefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await getResponse.Content.ReadAsStreamAsync(),
            options
        );

        Assert.NotNull(updatedArtefact);
        Assert.Equal("Updated Name", updatedArtefact.Name);
        Assert.Equal((ushort)1, updatedArtefact.ArtefactIndex);

        // Cleanup
        await DeleteTestArtefacts(loginData, artefacts);
        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestDeleteArtefact()
    {
        var loginData = await _utilities.CreateUserAndReturnLoginDataAsync();
        Assert.NotNull(loginData);

        // Create a test artefact
        var artefacts = await CreateTestArtefacts(loginData, 1);
        var artefact = artefacts[0];

        var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the artefact is deleted
        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);

        // Cleanup
        await _utilities.DeleteUserWithTokenAsync();
    }

    // Helper methods
    private async Task<List<ArtefactGetDTO>> CreateTestArtefacts(UserLoginResponseDTO loginData, int count)
    {
        var artefacts = new List<ArtefactGetDTO>();
        for (int i = 0; i < count; i++)
        {
            var content = new MultipartFormDataContent();
            var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
            imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
            content.Add(imageContent, "Image", "testImage.jpg");
            content.Add(new StringContent(loginData.userId), "UserId");
            content.Add(new StringContent(i.ToString()), "ArtefactIndex");
            content.Add(new StringContent($"Test Artefact {i}"), "Name");

            var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts")
            {
                Content = content
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

            var response = await _client.SendAsync(request);
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };

            var artefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
                await response.Content.ReadAsStreamAsync(),
                options
            );
            if (artefact != null)
            {
                artefacts.Add(artefact);
            }
        }
        return artefacts;
    }

    private async Task DeleteTestArtefacts(UserLoginResponseDTO loginData, List<ArtefactGetDTO> artefacts)
    {
        foreach (var artefact in artefacts)
        {
            var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Artefacts/{artefact.ArtefactId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            await _client.SendAsync(request);

            var assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", $"{artefact.ArtefactId}.jpg");
            if (File.Exists(assetsPath))
            {
                File.Delete(assetsPath);
            }
        }
    }
}
