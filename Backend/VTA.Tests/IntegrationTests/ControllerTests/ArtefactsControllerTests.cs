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

    public ArtefactsControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        _utilities = new Utilities(_client);
    }


    [Fact]
    public async Task TestAddArtefact()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
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
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
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
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        // Create a test artefact
        var artefacts = await CreateTestArtefacts(loginData, 1);
        var artefact = artefacts[0];

        // Update the artefact
        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");

        var content = new MultipartFormDataContent
        {
            { new StringContent(artefact.ArtefactId), "ArtefactId" },
            { new StringContent(loginData.userId), "UserId" },
            { new StringContent("1"), "ArtefactIndex" },  // Changed index
            { new StringContent("Updated Name"), "Name" }
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, $"/api/Users/Artefacts");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        request.Content = content;

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the update
        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Artefacts/{artefact.ArtefactId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);

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
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
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

    [Fact]
    public async Task TestAddArtefact_WithoutImage_ShouldReturnBadRequest()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var content = new MultipartFormDataContent
        {
            { new StringContent(loginData.userId), "UserId" },
            { new StringContent("0"), "ArtefactIndex" },
            { new StringContent("Test Name"), "Name" }
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestAddArtefact_WithWrongUserId_ShouldReturnForbidden()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        var content = new MultipartFormDataContent
        {
            { imageContent, "Image", "testImage.jpg" },
            { new StringContent("wrong-user-id"), "UserId" },
            { new StringContent("0"), "ArtefactIndex" },
            { new StringContent("Test Name"), "Name" }
        };
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestGetArtefact_NonExistentId_ShouldReturnNotFound()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Artefacts/non-existent-id");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestUpdateArtefact_NonExistentId_ShouldReturnBadRequest()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var content = new MultipartFormDataContent
        {
            { new StringContent("non-existent-id"), "ArtefactId" },
            { new StringContent(loginData.userId), "UserId" },
            { new StringContent("1"), "ArtefactIndex" },
            { new StringContent("Updated Name"), "Name" }
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Artefacts")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestDeleteArtefact_NonExistentId_ShouldReturnNotFound()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var request = new HttpRequestMessage(HttpMethod.Delete, "/api/Users/Artefacts/non-existent-id");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestGetArtefacts_WithoutAuthorization_ShouldReturnUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Artefacts");
        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // Helper methods
    private async Task<List<ArtefactGetDTO>> CreateTestArtefacts(UserLoginResponseDTO loginData, int count)
    {
        var artefacts = new List<ArtefactGetDTO>();
        var categoryId = await CreateTestCategory(loginData.userId, loginData.Token);
        for (int i = 0; i < count; i++)
        {
            var content = new MultipartFormDataContent();
            var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
            imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
            content.Add(imageContent, "Image", "testImage.jpg");
            content.Add(new StringContent(loginData.userId), "UserId");
            content.Add(new StringContent(i.ToString()), "ArtefactIndex");
            content.Add(new StringContent(categoryId), "CategoryId");
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

    private async Task<string> CreateTestCategory(string userId, string token)
    {
        var categoryPostDTO = new CategoryPostDTO
        {
            UserId = userId,
            Name = "Test Category"
        };

        var content = new MultipartFormDataContent
        {
            { new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId) },
            { new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name) }
        };

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        postRequest.Content = content;
        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.NotNull(category);

        return category.CategoryId;
    }
}