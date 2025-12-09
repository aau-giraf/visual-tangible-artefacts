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

        // Act: Create board with large but realistic position and size values
        // Note: MySQL FLOAT has limits (~-3.4e38 to 3.4e38), use realistic screen coordinates
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Extreme Values Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 99999.99f, PosY = -99999.99f, Width = 9999.99f, Height = 0.01f },
                new() { ArtefactId = artefactId, PosX = -99999.99f, PosY = 99999.99f, Width = 9999.99f, Height = 9999.99f },
                new() { ArtefactId = artefactId, PosX = 0, PosY = 0, Width = 1, Height = 1 }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Should handle large values within MySQL FLOAT range
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(3, board!.Artefacts.Count);

        // Verify large values are preserved
        var extremeArtefacts = board.Artefacts.OrderBy(a => a.PosX).ToList();
        
        // First artefact (most negative X)
        Assert.Equal(-99999.99f, extremeArtefacts[0].PosX, precision: 1);
        Assert.Equal(99999.99f, extremeArtefacts[0].PosY, precision: 1);
        
        // Last artefact (most positive X)
        Assert.Equal(99999.99f, extremeArtefacts[2].PosX, precision: 1);
        Assert.Equal(-99999.99f, extremeArtefacts[2].PosY, precision: 1);
    }

    [Fact]
    public async Task ManageBoard_CompleteLifecycle()
    {
        // Arrange: Test complete board lifecycle - create, add artefacts, update positions, delete artefacts
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Lifecycle Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;
        var userId = loginData.userId;
        
        var artefact1Id = await CreateTestArtefactAsync(token, userId, 0, "Lifecycle Artefact 1");
        var artefact2Id = await CreateTestArtefactAsync(token, userId, 1, "Lifecycle Artefact 2");
        var artefact3Id = await CreateTestArtefactAsync(token, userId, 2, "Lifecycle Artefact 3");

        // Act 1: Create initial board with three different artefacts
        var initialBoard = new SaveBoardRequestDTO
        {
            Name = "Lifecycle Test Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefact1Id, PosX = 100, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefact2Id, PosX = 300, PosY = 100, Width = 150, Height = 150 },
                new() { ArtefactId = artefact3Id, PosX = 500, PosY = 100, Width = 150, Height = 150 }
            }
        };

        var createResponse = await CreateBoardAsync(token, initialBoard);
        Assert.True(createResponse.StatusCode == HttpStatusCode.OK || createResponse.StatusCode == HttpStatusCode.Created);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await createResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        var boardId = board!.BoardId;
        
        Assert.Equal(3, board.Artefacts.Count);

        // Act 2: Get current board state for updates
        var midStateResponse = await GetBoardAsync(token, boardId);
        var midStateBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await midStateResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.Equal(3, midStateBoard!.Artefacts.Count);

        // Act 3: Update position of first artefact
        var firstArtefact = midStateBoard.Artefacts.First(a => a.ArtefactId == artefact1Id);
        var updatePositionRequest = new UpdateArtefactLayoutDTO
        {
            SavedArtefactId = firstArtefact.SavedArtefactId,
            ArtefactId = artefact1Id,
            PosX = 200,
            PosY = 200,
            Width = 180,
            Height = 180
        };
        
        var updateResponse = await UpdateArtefactPositionAsync(token, boardId, updatePositionRequest);
        Assert.True((int)updateResponse.StatusCode >= 200 && (int)updateResponse.StatusCode < 300);

        // Act 4: Delete second artefact
        var secondArtefact = midStateBoard.Artefacts.First(a => a.ArtefactId == artefact2Id);
        var deleteResponse = await DeleteArtefactInstanceAsync(token, boardId, secondArtefact.SavedArtefactId!);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Assert: Final verification
        var finalResponse = await GetBoardAsync(token, boardId);
        var finalBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await finalResponse.Content.ReadAsStreamAsync(), _jsonOptions);
        
        // Should have 2 artefacts remaining (artefact1 and artefact3)
        Assert.Equal(2, finalBoard!.Artefacts.Count);
        
        // Verify artefact2 is gone
        Assert.DoesNotContain(finalBoard.Artefacts, a => a.ArtefactId == artefact2Id);
        
        // Verify artefact1 has updated position and size
        var updatedArtefact1 = finalBoard.Artefacts.First(a => a.ArtefactId == artefact1Id);
        Assert.Equal(200f, updatedArtefact1.PosX);
        Assert.Equal(200f, updatedArtefact1.PosY);
        Assert.Equal(180f, updatedArtefact1.Width);
        Assert.Equal(180f, updatedArtefact1.Height);
        
        // Verify artefact3 is still present with original position
        var unchangedArtefact3 = finalBoard.Artefacts.First(a => a.ArtefactId == artefact3Id);
        Assert.Equal(500f, unchangedArtefact3.PosX);
        Assert.Equal(100f, unchangedArtefact3.PosY);
        
        // Verify data integrity - all SavedArtefactIds should be present
        Assert.All(finalBoard.Artefacts, a => Assert.NotNull(a.SavedArtefactId));
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

        // Act: Create board with zero and small sizes
        // Note: Database has default values (200) for width/height when not explicitly provided
        var boardRequest = new SaveBoardRequestDTO
        {
            Name = "Zero Size Board",
            Artefacts = new List<BoardArtefactLayoutDTO>
            {
                new() { ArtefactId = artefactId, PosX = 100, PosY = 100, Width = 0, Height = 0 },
                new() { ArtefactId = artefactId, PosX = 200, PosY = 200, Width = 50, Height = 75 },
                new() { ArtefactId = artefactId, PosX = 300, PosY = 300, Width = 0.1f, Height = 0.1f }
            }
        };

        var response = await CreateBoardAsync(token, boardRequest);
        
        // Assert: Should accept size values and apply defaults where appropriate
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(
            await response.Content.ReadAsStreamAsync(), _jsonOptions);
        
        Assert.NotNull(board);
        Assert.Equal(3, board!.Artefacts.Count);

        // Verify sizes: zero values get database defaults (200)
        var zeroSizeArtefact = board.Artefacts.First(a => a.PosX == 100);
        Assert.Equal(200, zeroSizeArtefact.Width);  // Database default applied
        Assert.Equal(200, zeroSizeArtefact.Height); // Database default applied

        var normalSizeArtefact = board.Artefacts.First(a => a.PosX == 200);
        Assert.Equal(50, normalSizeArtefact.Width);
        Assert.Equal(75, normalSizeArtefact.Height);

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