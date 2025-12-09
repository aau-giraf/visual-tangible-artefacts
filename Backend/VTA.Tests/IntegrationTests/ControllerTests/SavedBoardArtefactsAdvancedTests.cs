using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

/// <summary>
/// Advanced integration tests for complex saved board artefact scenarios
/// Tests edge cases, performance scenarios, and complex business logic
/// </summary>
public class SavedBoardArtefactsAdvancedTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly Utilities _utilities;
    private readonly JsonSerializerOptions _jsonOptions;

    public SavedBoardArtefactsAdvancedTests(CustomApplicationFactory factory)
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
    public async Task CreateBoard_WithManyArtefactInstances()
    {
        // Arrange: Create user and multiple artefacts
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Performance Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;

        // Create 5 artefacts
        var artefactIds = new List<string>();
        for (int i = 0; i < 5; i++)
        {
            var artefactId = await CreateTestArtefactAsync(token, userId, i, $"Performance Artefact {i + 1}");
            artefactIds.Add(artefactId);
        }

        // Act: Create board with many instances (each artefact placed multiple times)
        var artefactLayouts = new List<BoardArtefactLayoutDTO>();
        var random = new Random(42); // Fixed seed for reproducible tests
        
        for (int i = 0; i < 25; i++) // 25 total artefact instances
        {
            var artefactId = artefactIds[i % artefactIds.Count]; // Distribute across available artefacts
            artefactLayouts.Add(new BoardArtefactLayoutDTO
            {
                ArtefactId = artefactId,
                PosX = random.Next(0, 1000),
                PosY = random.Next(0, 1000),
                Width = random.Next(100, 300),
                Height = random.Next(100, 300)
            });
        }

        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "High Density Board",
            Artefacts = artefactLayouts
        };

        var startTime = DateTime.UtcNow;
        var response = await CreateBoardAsync(token, boardRequest);
        var endTime = DateTime.UtcNow;

        // Assert: Should handle large number of instances efficiently
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(25, board!.Artefacts.Count);
        Assert.All(board.Artefacts, a => Assert.NotNull(a.SavedArtefactId));
        
        // Performance assertion - should complete within reasonable time
        var duration = endTime - startTime;
        Assert.True(duration.TotalSeconds < 5, $"Board creation took {duration.TotalSeconds} seconds, expected < 5");

        // Verify all SavedArtefactIds are unique
        var savedArtefactIds = board.Artefacts.Select(a => a.SavedArtefactId).ToList();
        Assert.Equal(25, savedArtefactIds.Distinct().Count());
    }

    [Fact]
    public async Task UpdateMultipleArtefactInstances_Concurrently()
    {
        // Arrange: Create board with multiple instances of same artefact
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Concurrency Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Concurrency Test Artefact");

        // Create board with 5 instances
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Concurrency Test Board",
            Artefacts = Enumerable.Range(0, 5).Select(i => new BoardArtefactLayoutDTO
            {
                ArtefactId = artefactId,
                PosX = i * 100,
                PosY = i * 100,
                Width = 150,
                Height = 150
            }).ToList()
        };

        var createResponse = await CreateBoardAsync(token, boardRequest);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        var boardId = board!.BoardId;

        // Act: Perform concurrent updates
        var updateTasks = board.Artefacts.Select(async (artefact, index) =>
        {
            var updateRequest = new UpdateArtefactLayoutDTO
            {
                SavedArtefactId = artefact.SavedArtefactId,
                ArtefactId = artefact.ArtefactId,
                PosX = 500 + index * 10,
                PosY = 600 + index * 10,
                Width = 200 + index * 5,
                Height = 200 + index * 5
            };
            
            return await UpdateArtefactPositionAsync(token, boardId, updateRequest);
        }).ToArray();

        var responses = await Task.WhenAll(updateTasks);

        // Assert: All updates should succeed
        Assert.All(responses, response => Assert.Equal(HttpStatusCode.OK, response.StatusCode));

        // Verify final state is consistent
        var finalBoardResponse = await GetBoardAsync(token, boardId);
        var finalBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await finalBoardResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(finalBoard);
        Assert.Equal(5, finalBoard!.Artefacts.Count);

        // Verify each instance has the expected updated position
        for (int i = 0; i < 5; i++)
        {
            var expectedPosX = 500 + i * 10;
            var expectedPosY = 600 + i * 10;
            var expectedWidth = 200 + i * 5;
            var expectedHeight = 200 + i * 5;

            Assert.Contains(finalBoard.Artefacts, a => 
                a.PosX == expectedPosX && 
                a.PosY == expectedPosY && 
                a.Width == expectedWidth && 
                a.Height == expectedHeight);
        }
    }

    [Fact]
    public async Task CreateBoard_WithExtremePositionValues()
    {
        // Arrange: Test with extreme float values
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Extreme Values Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Extreme Position Artefact");

        // Act: Create board with extreme position and size values
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Extreme Values Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = float.MaxValue, PosY = float.MinValue, Width = 999999.99f, Height = 0.01f },
                new() { ArtefactId = artefactId, PosX = -999999.99f, PosY = 999999.99f, Width = float.MaxValue, Height = float.MaxValue },
                new() { ArtefactId = artefactId, PosX = 0, PosY = 0, Width = 1, Height = 1 }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Should handle extreme values
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(3, board!.Artefacts.Count);

        // Verify extreme values are preserved
        var extremeArtefacts = board.Artefacts.OrderBy(a => a.PosX).ToList();
        
        // First artefact (most negative X)
        Assert.Equal(-999999.99f, extremeArtefacts[0].PosX, precision: 2);
        Assert.Equal(999999.99f, extremeArtefacts[0].PosY, precision: 2);
        
        // Last artefact (most positive X)
        Assert.Equal(float.MaxValue, extremeArtefacts[2].PosX);
        Assert.Equal(float.MinValue, extremeArtefacts[2].PosY);
    }

    [Fact]
    public async Task ManageBoard_CompleteLifecycle()
    {
        // Arrange: Complete lifecycle test
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Lifecycle Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        
        var artefact1Id = await CreateTestArtefactAsync(token, userId, 0, "Lifecycle Artefact 1");
        var artefact2Id = await CreateTestArtefactAsync(token, userId, 1, "Lifecycle Artefact 2");

        // Act 1: Create initial board
        var initialBoard = new SaveBoardRequestDTO
        {
            Name = "Lifecycle Test Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefact1Id, PosX = 100, PosY = 100, Width = 150, Height = 150 }
            }
        };

        var createResponse = await CreateBoardAsync(token, initialBoard);
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        var boardId = board!.BoardId;

        // Act 2: Add more artefact instances
        var addArtefactRequest = new UpdateArtefactLayoutDTO
        {
            ArtefactId = artefact2Id,
            PosX = 300,
            PosY = 300,
            Width = 200,
            Height = 200
        };
        
        var addResponse = await UpdateArtefactPositionAsync(token, boardId, addArtefactRequest);
        Assert.Equal(HttpStatusCode.OK, addResponse.StatusCode);

        // Add duplicate of first artefact
        var duplicateRequest = new UpdateArtefactLayoutDTO
        {
            ArtefactId = artefact1Id,
            PosX = 500,
            PosY = 500,
            Width = 100,
            Height = 100
        };
        
        await UpdateArtefactPositionAsync(token, boardId, duplicateRequest);

        // Act 3: Verify current state
        var midStateResponse = await GetBoardAsync(token, boardId);
        var midStateBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await midStateResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.Equal(3, midStateBoard!.Artefacts.Count); // Original + 2 added

        // Act 4: Remove one specific instance
        var instanceToRemove = midStateBoard.Artefacts.First(a => a.ArtefactId == artefact1Id && a.PosX == 100);
        var deleteResponse = await DeleteArtefactInstanceAsync(token, boardId, instanceToRemove.SavedArtefactId!);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Act 5: Update remaining instances
        var remainingInstances = await GetBoardAsync(token, boardId);
        var remainingBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await remainingInstances.Content.ReadAsStreamAsync(), _jsonOptions);
        
        foreach (var artefact in remainingBoard!.Artefacts)
        {
            var updateRequest = new UpdateArtefactLayoutDTO
            {
                SavedArtefactId = artefact.SavedArtefactId,
                ArtefactId = artefact.ArtefactId,
                PosX = artefact.PosX + 50, // Shift all artefacts
                PosY = artefact.PosY + 50,
                Width = artefact.Width,
                Height = artefact.Height
            };
            
            await UpdateArtefactPositionAsync(token, boardId, updateRequest);
        }

        // Assert: Final verification
        var finalResponse = await GetBoardAsync(token, boardId);
        var finalBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await finalResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.Equal(2, finalBoard!.Artefacts.Count); // Should have 2 after deletion
        
        // Verify the deleted instance is gone
        Assert.DoesNotContain(finalBoard.Artefacts, a => a.PosX == 150 && a.PosY == 150); // Original position + 50
        
        // Verify remaining instances are shifted
        Assert.Contains(finalBoard.Artefacts, a => a.PosX == 350 && a.PosY == 350); // 300 + 50
        Assert.Contains(finalBoard.Artefacts, a => a.PosX == 550 && a.PosY == 550); // 500 + 50

        // Verify data integrity - all SavedArtefactIds should still be unique and not null
        Assert.All(finalBoard.Artefacts, a => Assert.NotNull(a.SavedArtefactId));
        var savedIds = finalBoard.Artefacts.Select(a => a.SavedArtefactId).ToList();
        Assert.Equal(2, savedIds.Distinct().Count());
    }

    [Fact]
    public async Task CreateBoard_WithZeroSizedArtefacts()
    {
        // Arrange
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Zero Size Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Zero Size Artefact");

        // Act: Create board with zero and negative sizes
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Zero Size Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 0, Height = 0 },
                new() { ArtefactId = artefactId, PosX = 200, PosY = 200, Width = -50, Height = -75 },
                new() { ArtefactId = artefactId, PosX = 300, PosY = 300, Width = 0.1f, Height = 0.1f }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Should accept unusual size values (validation is business logic)
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(3, board!.Artefacts.Count);

        // Verify unusual sizes are preserved
        var zeroSizeArtefact = board.Artefacts.First(a => a.PosX == 100);
        Assert.Equal(0, zeroSizeArtefact.Width);
        Assert.Equal(0, zeroSizeArtefact.Height);

        var negativeSizeArtefact = board.Artefacts.First(a => a.PosX == 200);
        Assert.Equal(-50, negativeSizeArtefact.Width);
        Assert.Equal(-75, negativeSizeArtefact.Height);

        var tinyArtefact = board.Artefacts.First(a => a.PosX == 300);
        Assert.Equal(0.1f, tinyArtefact.Width, precision: 2);
        Assert.Equal(0.1f, tinyArtefact.Height, precision: 2);
    }

    [Fact]
    public async Task GetAllBoards_WithMultipleBoards()
    {
        // Arrange: Create multiple boards
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Multi Board Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        var artefactId = await CreateTestArtefactAsync(token, userId, 0, "Multi Board Artefact");

        var boardNames = new[] { "Board One", "Board Two", "Board Three" };
        var createdBoardIds = new List<string>();

        // Create multiple boards with different numbers of artefacts
        for (int i = 0; i < boardNames.Length; i++)
        {
            var artefactCount = i + 1; // 1, 2, 3 artefacts respectively
            var artefacts = Enumerable.Range(0, artefactCount).Select(j => new BoardArtefactLayoutDTO
            {
                ArtefactId = artefactId,
                PosX = j * 100,
                PosY = j * 100,
                Width = 150,
                Height = 150
            }).ToList();

            var boardRequest = new SaveBoardRequestDTO
            {
                Name = boardNames[i],
                Artefacts = artefacts
            };

            var response = await CreateBoardAsync(token, boardRequest);
            var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
                await response.Content.ReadAsStreamAsync(), _jsonOptions);
            
            createdBoardIds.Add(board!.BoardId);
        }

        // Act: Get all boards
        var allBoardsResponse = await GetAllBoardsAsync(token);
        
        // Assert
        Assert.Equal(HttpStatusCode.OK, allBoardsResponse.StatusCode);
        
        var allBoards = await JsonSerializer.DeserializeAsync<List<BoardLayoutResponseDTO>>(
            await allBoardsResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(allBoards);
        Assert.Equal(3, allBoards!.Count);

        // Verify each board has correct artefact count
        for (int i = 0; i < boardNames.Length; i++)
        {
            var board = allBoards.First(b => b.Name == boardNames[i]);
            Assert.Equal(i + 1, board.Artefacts.Count);
            Assert.Contains(board.BoardId, createdBoardIds);
        }
    }

    // Helper methods (same as in SavedBoardArtefactsTests)
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

    private async Task<HttpResponseMessage> GetAllBoardsAsync(string token)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards");
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
}