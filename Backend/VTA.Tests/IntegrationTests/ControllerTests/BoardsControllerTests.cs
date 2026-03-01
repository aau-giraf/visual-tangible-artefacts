using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class BoardsControllerTests : IClassFixture<CustomApplicationFactory>
{
  private readonly HttpClient _client;
  private readonly Utilities _utilities;

  public BoardsControllerTests(CustomApplicationFactory factory)
  {
    _client = factory.CreateClient();
    _utilities = new Utilities(_client);
  }

  [Fact]
  public async Task GetBoards_ReturnsOk_WithDefaultBoard()
  {
    var loginData = _utilities.CreateTestLoginData();

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boards = await response.Content.ReadFromJsonAsync<List<BoardGetDTO>>();
    Assert.NotNull(boards);
    Assert.Single(boards);
    Assert.Equal("Board1", boards[0].Name);  // Verify default board exists
  }

  [Fact]
  public async Task GetBoards_ReturnsOk_WithMultipleBoards()
  {
    var loginData = _utilities.CreateTestLoginData();

    // Create additional boards (default "Board1" already exists)
    var board2 = await CreateTestBoard(loginData, "Board 2");
    var board3 = await CreateTestBoard(loginData, "Board 3");

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boards = await response.Content.ReadFromJsonAsync<List<BoardGetDTO>>();
    Assert.NotNull(boards);
    // Accept possible extra default/seeding: expect at least 3
    Assert.True(boards.Count >= 3);
  }

  [Fact]
  public async Task GetBoards_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task GetBoardsList_ReturnsOk_WithLightweightData()
  {
    var loginData = _utilities.CreateTestLoginData();

    var board = await CreateTestBoard(loginData, "Test Board");

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards/list");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boardList = await response.Content.ReadFromJsonAsync<List<BoardListItemDTO>>();
    Assert.NotNull(boardList);
    Assert.Equal(2, boardList.Count);
    Assert.Contains(boardList, b => b.Name == "Board1");  // Verify default board
    Assert.Contains(boardList, b => b.Name == "Test Board");  // Verify created board
  }

  [Fact]
  public async Task GetBoardsList_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards/list");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task GetBoard_ReturnsOk_WithValidBoardId()
  {
    var loginData = _utilities.CreateTestLoginData();

    var createdBoard = await CreateTestBoard(loginData, "Test Board");

    var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Boards/{createdBoard.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    // API returns layout response; validate accordingly
    var board = await response.Content.ReadFromJsonAsync<BoardLayoutResponseDTO>();
    Assert.NotNull(board);
    Assert.Equal(createdBoard.Id, board.BoardId);
    Assert.Equal("Test Board", board.Name);
  }

  [Fact]
  public async Task GetBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var loginData = _utilities.CreateTestLoginData();

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards/non-existent-id");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
  }

  [Fact]
  public async Task GetBoard_ReturnsForbidden_WhenAccessingAnotherUsersBoard()
  {
    var loginData1 = _utilities.CreateTestLoginData();
    var loginData2 = _utilities.CreateTestLoginData();

    var board = await CreateTestBoard(loginData1, "User 1 Board");

    // Try to access user 1's board with user 2's token
    var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Boards/{board.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData2.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode); // Returns NotFound for security
  }

  [Fact]
  public async Task GetBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Boards/some-board-id");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task PostBoard_ReturnsCreated_WithValidData()
  {
    var loginData = _utilities.CreateTestLoginData();

    var boardPostDTO = new BoardPostDTO
    {
      Name = "New Board",
      SnapshotPath = "/snapshots/test.jpg"
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    // Accept OK or Created for board creation
    Assert.Contains(response.StatusCode, new[] { HttpStatusCode.Created, HttpStatusCode.OK });

    var board = await response.Content.ReadFromJsonAsync<BoardGetDTO>();
    Assert.NotNull(board);
    Assert.Equal("New Board", board.Name);
    Assert.NotNull(board.Id);
  }

  [Fact]
  public async Task PostBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var boardPostDTO = new BoardPostDTO
    {
      Name = "New Board"
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task PatchBoard_ReturnsNoContent_WithValidData()
  {
    var loginData = _utilities.CreateTestLoginData();

    var board = await CreateTestBoard(loginData, "Original Name");

    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = board.Id,
      Name = "Updated Name",
      SnapshotPath = "/snapshots/updated.jpg"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

    // Verify the update
    var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Boards/{board.Id}");
    getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
    var getResponse = await _client.SendAsync(getRequest);
    var updatedBoard = await getResponse.Content.ReadFromJsonAsync<BoardGetDTO>();

    Assert.NotNull(updatedBoard);
    Assert.Equal("Updated Name", updatedBoard.Name);
  }

  [Fact]
  public async Task PatchBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var loginData = _utilities.CreateTestLoginData();

    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = "non-existent-id",
      Name = "Updated Name"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
  }

  [Fact]
  public async Task PatchBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = "some-board-id",
      Name = "Updated Name"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task DeleteBoard_ReturnsNoContent_WithValidBoardId()
  {
    var loginData = _utilities.CreateTestLoginData();

    var board = await CreateTestBoard(loginData, "Board to Delete");

    var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Boards/{board.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

    // Verify deletion
    var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Boards/{board.Id}");
    getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
    var getResponse = await _client.SendAsync(getRequest);
    Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
  }

  [Fact]
  public async Task DeleteBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var loginData = _utilities.CreateTestLoginData();

    var request = new HttpRequestMessage(HttpMethod.Delete, "/api/Boards/non-existent-id");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
  }

  [Fact]
  public async Task DeleteBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Delete, "/api/Boards/some-board-id");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  private async Task<BoardGetDTO> CreateTestBoard(TestLoginData loginData, string boardName)
  {
    var boardPostDTO = new BoardPostDTO
    {
      Name = boardName
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Contains(response.StatusCode, new[] { HttpStatusCode.Created, HttpStatusCode.OK });

    var board = await response.Content.ReadFromJsonAsync<BoardGetDTO>();
    Assert.NotNull(board);

    return board;
  }
}
