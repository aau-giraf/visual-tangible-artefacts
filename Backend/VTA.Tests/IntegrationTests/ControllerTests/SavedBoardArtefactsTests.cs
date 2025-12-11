using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

/// <summary>
/// Integration tests for saved board artefacts functionality
/// Tests the complete workflow of creating boards, adding artefacts, and managing their positions
/// </summary>
public class SavedBoardArtefactsTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly Utilities _utilities;
    private readonly JsonSerializerOptions _jsonOptions;

    public SavedBoardArtefactsTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        _utilities = new Utilities(_client);
        _jsonOptions = new JsonSerializerOptions 
        { 
            PropertyNameCaseInsensitive = true, 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase 
        };
    }

    [Fact]
    public async Task CreateBoard_WithMultipleArtefacts_ShouldSaveCorrectly()
    {
        // Arrange: Create user and login
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Board Creator");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;

        // Create multiple artefacts
        var artefactIds = new List<string>();
        for (int i = 0; i < 3; i++)
        {
            var artefactId = await CreateTestArtefactAsync(token, userId, i, $"Test Artefact {i + 1}");
            artefactIds.Add(artefactId);
        }

        // Act: Create a board with all artefacts
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Multi-Artefact Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactIds[0], PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefactIds[1], PosX = 300, PosY = 200, Width = 200, Height = 180 },
                new() { ArtefactId = artefactIds[2], PosX = 500, PosY = 350, Width = 120, Height = 220 }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Board created successfully
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal("Multi-Artefact Board", board!.Name);
        Assert.Equal(3, board.Artefacts.Count);
        
        // Verify each artefact is saved with correct properties
        for (int i = 0; i < 3; i++)
        {
            var artefact = board.Artefacts.FirstOrDefault(a => a.ArtefactId == artefactIds[i]);
            Assert.NotNull(artefact);
            Assert.NotNull(artefact!.SavedArtefactId);
            Assert.NotEmpty(artefact.SavedArtefactId!);
        }

        // Verify positions are saved correctly
        var firstArtefact = board.Artefacts.First(a => a.ArtefactId == artefactIds[0]);
        Assert.Equal(100, firstArtefact.PosX);
        Assert.Equal(100, firstArtefact.PosY);
        Assert.Equal(150, firstArtefact.Width);
        Assert.Equal(150, firstArtefact.Height);
    }

    [Fact]
    public async Task CreateBoard_WithDuplicateArtefacts_ShouldCreateSeparateInstances()
    {
        // Arrange: Create user and one artefact
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Duplicate Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Duplicate Artefact");

        // Act: Create board with same artefact in multiple positions
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Duplicate Artefacts Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefactId, PosX = 400, PosY = 300, Width = 200, Height = 200 },
                new() { ArtefactId = artefactId, PosX = 200, PosY = 500, Width = 180, Height = 120 }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Board created with separate instances
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(3, board!.Artefacts.Count);
        
        // All artefacts should have the same ArtefactId but different SavedArtefactIds
        Assert.All(board.Artefacts, a => Assert.Equal(artefactId, a.ArtefactId));
        
        var savedArtefactIds = board.Artefacts.Select(a => a.SavedArtefactId).ToList();
        Assert.Equal(3, savedArtefactIds.Distinct().Count()); // All SavedArtefactIds should be unique
        
        // Verify positions are correctly saved
        var positions = board.Artefacts.Select(a => new { a.PosX, a.PosY }).ToList();
        Assert.Contains(positions, p => p.PosX == 100 && p.PosY == 100);
        Assert.Contains(positions, p => p.PosX == 400 && p.PosY == 300);
        Assert.Contains(positions, p => p.PosX == 200 && p.PosY == 500);
    }

    [Fact]
    public async Task UpdateArtefactPosition_ShouldModifyCorrectInstance()
    {
        // Arrange: Create board with duplicate artefacts
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Position Updater");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Position Test Artefact");

        // Create board with two instances of same artefact
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Position Update Test Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefactId, PosX = 300, PosY = 300, Width = 200, Height = 200 }
            }
        };

        var createResponse = await CreateBoardAsync(token, boardRequest);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        var boardId = board!.BoardId;
        var firstInstance = board.Artefacts[0];
        var secondInstance = board.Artefacts[1];

        // Act: Update position of first instance
        var updateRequest = new UpdateArtefactLayoutDTO
        {
            SavedArtefactId = firstInstance.SavedArtefactId,
            ArtefactId = artefactId,
            PosX = 500,
            PosY = 400,
            Width = 250,
            Height = 180
        };

        var updateResponse = await UpdateArtefactPositionAsync(token, boardId, updateRequest);
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        // Assert: Verify only the first instance was updated
        var updatedBoardResponse = await GetBoardAsync(token, boardId);
        var updatedBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await updatedBoardResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(updatedBoard);
        Assert.Equal(2, updatedBoard!.Artefacts.Count);

        var updatedFirst = updatedBoard.Artefacts.First(a => a.SavedArtefactId == firstInstance.SavedArtefactId);
        var unchangedSecond = updatedBoard.Artefacts.First(a => a.SavedArtefactId == secondInstance.SavedArtefactId);

        // First instance should be updated
        Assert.Equal(500, updatedFirst.PosX);
        Assert.Equal(400, updatedFirst.PosY);
        Assert.Equal(250, updatedFirst.Width);
        Assert.Equal(180, updatedFirst.Height);

        // Second instance should remain unchanged
        Assert.Equal(300, unchangedSecond.PosX);
        Assert.Equal(300, unchangedSecond.PosY);
        Assert.Equal(200, unchangedSecond.Width);
        Assert.Equal(200, unchangedSecond.Height);
    }

    [Fact]
    public async Task DeleteSpecificArtefactInstance_ShouldRemoveOnlyThatInstance()
    {
        // Arrange: Create board with multiple instances
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Delete Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Delete Test Artefact");

        // Create board with three instances
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Delete Test Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefactId, PosX = 300, PosY = 300, Width = 200, Height = 200 },
                new() { ArtefactId = artefactId, PosX = 500, PosY = 500, Width = 100, Height = 100 }
            }
        };

        var createResponse = await CreateBoardAsync(token, boardRequest);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        var boardId = board!.BoardId;
        var instanceToDelete = board.Artefacts[1]; // Delete middle instance

        // Act: Delete specific instance
        var deleteResponse = await DeleteArtefactInstanceAsync(token, boardId, instanceToDelete.SavedArtefactId!);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Assert: Verify only that instance was deleted
        var updatedBoardResponse = await GetBoardAsync(token, boardId);
        var updatedBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await updatedBoardResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(updatedBoard);
        Assert.Equal(2, updatedBoard!.Artefacts.Count);
        
        // Verify the deleted instance is gone
        Assert.DoesNotContain(updatedBoard.Artefacts, a => a.SavedArtefactId == instanceToDelete.SavedArtefactId);
        
        // Verify remaining instances are still there with correct positions
        var remainingPositions = updatedBoard.Artefacts.Select(a => new { a.PosX, a.PosY }).ToList();
        Assert.Contains(remainingPositions, p => p.PosX == 100 && p.PosY == 100);
        Assert.Contains(remainingPositions, p => p.PosX == 500 && p.PosY == 500);
        Assert.DoesNotContain(remainingPositions, p => p.PosX == 300 && p.PosY == 300);
    }

    [Fact]
    public async Task CreateBoard_WithNonExistentArtefact_ShouldReturnBadRequest()
    {
        // Arrange
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Error Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var nonExistentArtefactId = Guid.NewGuid().ToString();

        // Act: Try to create board with non-existent artefact
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Invalid Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = nonExistentArtefactId, PosX = 100, PosY = 100, Width = 150, Height = 150 }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Should return error
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetBoard_ShouldReturnCorrectArtefactData()
    {
        // Arrange: Create board with artefacts
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Data Verifier");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Data Test Artefact");

        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Data Verification Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 123.5f, PosY = 456.7f, Width = 789.1f, Height = 234.5f }
            }
        };

        var createResponse = await CreateBoardAsync(token, boardRequest);
        var createdBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        // Act: Get the board
        var getResponse = await GetBoardAsync(token, createdBoard!.BoardId);
        
        // Assert: Verify data integrity
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var retrievedBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await getResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(retrievedBoard);
        Assert.Equal("Data Verification Board", retrievedBoard!.Name);
        Assert.Single(retrievedBoard.Artefacts);
        
        var artefact = retrievedBoard.Artefacts[0];
        Assert.Equal(artefactId, artefact.ArtefactId);
        Assert.Equal(123.5f, artefact.PosX);
        Assert.Equal(456.7f, artefact.PosY);
        Assert.Equal(789.1f, artefact.Width);
        Assert.Equal(234.5f, artefact.Height);
        Assert.NotNull(artefact.SavedArtefactId);
    }

    [Fact]
    public async Task DeleteBoard_ShouldRemoveBoardAndAllArtefactInstances()
    {
        // Arrange: Create board with artefacts
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Board Deleter");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Board Delete Test");

        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Board to Delete",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefactId, PosX = 300, PosY = 300, Width = 200, Height = 200 }
            }
        };

        var createResponse = await CreateBoardAsync(token, boardRequest);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        var boardId = board!.BoardId;

        // Act: Delete the board
        var deleteResponse = await DeleteBoardAsync(token, boardId);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Assert: Board should no longer exist
        var getResponse = await GetBoardAsync(token, boardId);
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    // Helper methods
    private async Task<string> CreateTestArtefactAsync(string token, string userId, int index, string name)
    {
        var content = new MultipartFormDataContent();
        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        
        content.Add(imageContent, "Image", "testImage.jpg");
        content.Add(new StringContent(userId), "UserId");
        content.Add(new StringContent(index.ToString()), "ArtefactIndex");
        content.Add(new StringContent(name), "Name");

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts") { Content = content };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var created = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        Assert.NotNull(created);
        return created!.ArtefactId;
    }

    private async Task<HttpResponseMessage> CreateBoardAsync(string token, SaveBoardRequestDTO request)
    {
        var httpRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards")
        {
            Content = JsonContent.Create(request)
        };
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(httpRequest);
    }

    private async Task<HttpResponseMessage> GetBoardAsync(string token, string boardId)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{boardId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request);
    }

    private async Task<HttpResponseMessage> UpdateArtefactPositionAsync(string token, string boardId, UpdateArtefactLayoutDTO update)
    {
        var request = new HttpRequestMessage(HttpMethod.Patch, $"/api/Users/Boards/{boardId}/artefacts")
        {
            Content = JsonContent.Create(update)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request);
    }

    private async Task<HttpResponseMessage> DeleteArtefactInstanceAsync(string token, string boardId, string savedArtefactId)
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Boards/{boardId}/artefacts/{savedArtefactId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request);
    }

    private async Task<HttpResponseMessage> DeleteBoardAsync(string token, string boardId)
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Boards/{boardId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request);
    }
}