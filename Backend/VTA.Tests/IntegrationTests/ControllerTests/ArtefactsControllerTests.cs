using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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

        // File is now stored in user-specific folder with "image_" prefix: Assets/Artefacts/{userId}/image_{artefactId}.jpg
        var assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData.userId, $"image_{artefact.ArtefactId}.jpg");

        await Task.Delay(1000); // Increased delay for slower systems

        Assert.True(File.Exists(assetsPath), $"File not found at: {assetsPath}");

        if (File.Exists(assetsPath))
        {
            File.Delete(assetsPath);
        }

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestArtefactImageUpload_VerifyCorrectFilePathStructure()
    {
        // Arrange: Create a test user
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
        Assert.NotNull(loginData);

        // Arrange: Prepare test image data
        var testImageBytes = await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage");
        var content = new MultipartFormDataContent();
        var imageContent = new ByteArrayContent(testImageBytes);
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(imageContent, "Image", "testImage.jpg");
        content.Add(new StringContent(loginData.userId), "UserId");
        content.Add(new StringContent("0"), "ArtefactIndex");
        content.Add(new StringContent("File Path Test Artefact"), "Name");

        // Act: Upload the artefact
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var response = await _client.SendAsync(request);

        // Assert: Upload was successful
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var artefact = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await response.Content.ReadAsStreamAsync(),
            options
        );
        Assert.NotNull(artefact);

        await Task.Delay(1000); // Allow time for file system operations

        // Assert: File exists at the correct path with correct naming convention
        // Expected: Assets/Artefacts/{userId}/image_{artefactId}.jpg
        var correctPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData.userId, $"image_{artefact.ArtefactId}.jpg");
        Assert.True(File.Exists(correctPath), $"File should exist at correct path: {correctPath}");

        // Assert: User-specific directory exists
        var userDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData.userId);
        Assert.True(Directory.Exists(userDirectory), $"User-specific directory should exist: {userDirectory}");

        // Assert: File does NOT exist in incorrect locations
        var incorrectPathRoot = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", $"image_{artefact.ArtefactId}.jpg");
        Assert.False(File.Exists(incorrectPathRoot), $"File should NOT exist in root Artefacts folder: {incorrectPathRoot}");

        var incorrectPathWithoutPrefix = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData.userId, $"{artefact.ArtefactId}.jpg");
        Assert.False(File.Exists(incorrectPathWithoutPrefix), $"File should NOT exist without 'image_' prefix: {incorrectPathWithoutPrefix}");

        // Assert: Verify file content matches uploaded content
        var savedFileBytes = await File.ReadAllBytesAsync(correctPath);
        Assert.Equal(testImageBytes.Length, savedFileBytes.Length);
        Assert.True(testImageBytes.SequenceEqual(savedFileBytes), "Saved file content should match uploaded content");

        // Cleanup
        if (File.Exists(correctPath))
        {
            File.Delete(correctPath);
        }

        await _utilities.DeleteUserWithTokenAsync();
    }

    [Fact]
    public async Task TestArtefactImageUpload_VerifyUserIsolation()
    {
        // Arrange: Create two different test users
        var username1 = _utilities.GenerateUniqueUsername();
        var username2 = _utilities.GenerateUniqueUsername();

        var (signUpStatus1, loginData1) = await _utilities.SignUpUserAsync(username1, "testpassword1", "Test User 1");
        var (signUpStatus2, loginData2) = await _utilities.SignUpUserAsync(username2, "testpassword2", "Test User 2");

        Assert.Equal(HttpStatusCode.Created, signUpStatus1);
        Assert.Equal(HttpStatusCode.Created, signUpStatus2);
        Assert.NotNull(loginData1);
        Assert.NotNull(loginData2);

        // Arrange: Prepare test image data for both users
        var testImageBytes = await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage");

        // Act: Upload artefact for user 1
        var content1 = new MultipartFormDataContent();
        var imageContent1 = new ByteArrayContent(testImageBytes);
        imageContent1.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content1.Add(imageContent1, "Image", "testImage1.jpg");
        content1.Add(new StringContent(loginData1.userId), "UserId");
        content1.Add(new StringContent("0"), "ArtefactIndex");
        content1.Add(new StringContent("User 1 Artefact"), "Name");

        var request1 = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts") { Content = content1 };
        request1.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData1.Token);
        var response1 = await _client.SendAsync(request1);

        // Act: Upload artefact for user 2
        var content2 = new MultipartFormDataContent();
        var imageContent2 = new ByteArrayContent(testImageBytes);
        imageContent2.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content2.Add(imageContent2, "Image", "testImage2.jpg");
        content2.Add(new StringContent(loginData2.userId), "UserId");
        content2.Add(new StringContent("0"), "ArtefactIndex");
        content2.Add(new StringContent("User 2 Artefact"), "Name");

        var request2 = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts") { Content = content2 };
        request2.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData2.Token);
        var response2 = await _client.SendAsync(request2);

        // Assert: Both uploads were successful
        Assert.Equal(HttpStatusCode.OK, response1.StatusCode);
        Assert.Equal(HttpStatusCode.OK, response2.StatusCode);

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var artefact1 = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await response1.Content.ReadAsStreamAsync(), options);
        var artefact2 = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await response2.Content.ReadAsStreamAsync(), options);

        Assert.NotNull(artefact1);
        Assert.NotNull(artefact2);

        await Task.Delay(1000); // Allow time for file system operations

        // Assert: Each user's file exists in their own directory
        var user1FilePath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData1.userId, $"image_{artefact1.ArtefactId}.jpg");
        var user2FilePath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData2.userId, $"image_{artefact2.ArtefactId}.jpg");

        Assert.True(File.Exists(user1FilePath), $"User 1's file should exist at: {user1FilePath}");
        Assert.True(File.Exists(user2FilePath), $"User 2's file should exist at: {user2FilePath}");

        // Assert: User directories are separate
        var user1Directory = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData1.userId);
        var user2Directory = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData2.userId);

        Assert.True(Directory.Exists(user1Directory), $"User 1's directory should exist");
        Assert.True(Directory.Exists(user2Directory), $"User 2's directory should exist");
        Assert.NotEqual(user1Directory, user2Directory);

        // Assert: User 1's file does NOT exist in User 2's directory and vice versa
        var wrongPath1 = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData2.userId, $"image_{artefact1.ArtefactId}.jpg");
        var wrongPath2 = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData1.userId, $"image_{artefact2.ArtefactId}.jpg");

        Assert.False(File.Exists(wrongPath1), $"User 1's file should NOT exist in User 2's directory");
        Assert.False(File.Exists(wrongPath2), $"User 2's file should NOT exist in User 1's directory");

        // Cleanup
        if (File.Exists(user1FilePath)) File.Delete(user1FilePath);
        if (File.Exists(user2FilePath)) File.Delete(user2FilePath);

        // Delete both users
        await _utilities.DeleteUserAsync(loginData1.userId, loginData1.Token);
        await _utilities.DeleteUserAsync(loginData2.userId, loginData2.Token);
    }

    [Fact]
    public async Task TestGetAllArtefacts()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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
        Assert.Equal(HttpStatusCode.Created, signUpStatus);
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

            // File is stored in user-specific folder with "image_" prefix: Assets/Artefacts/{userId}/image_{artefactId}.jpg
            var assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", loginData.userId, $"image_{artefact.ArtefactId}.jpg");
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