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
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boards = await response.Content.ReadFromJsonAsync<List<BoardGetDTO>>();
    Assert.NotNull(boards);
    Assert.Single(boards);
    Assert.Equal("Board1", boards[0].Name);  // Verify default board exists

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task GetBoards_ReturnsOk_WithMultipleBoards()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    // Create additional boards (default "Board1" already exists)
    var board2 = await CreateTestBoard(loginData, "Board 2");
    var board3 = await CreateTestBoard(loginData, "Board 3");

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boards = await response.Content.ReadFromJsonAsync<List<BoardGetDTO>>();
    Assert.NotNull(boards);
    Assert.Equal(3, boards.Count);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task GetBoards_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task GetBoardsList_ReturnsOk_WithLightweightData()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var board = await CreateTestBoard(loginData, "Test Board");

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/list");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var boardList = await response.Content.ReadFromJsonAsync<List<BoardListItemDTO>>();
    Assert.NotNull(boardList);
    Assert.Equal(2, boardList.Count);
    Assert.Contains(boardList, b => b.Name == "Board1");  // Verify default board
    Assert.Contains(boardList, b => b.Name == "Test Board");  // Verify created board

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task GetBoardsList_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/list");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task GetBoard_ReturnsOk_WithValidBoardId()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var createdBoard = await CreateTestBoard(loginData, "Test Board");

    var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{createdBoard.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);

    var board = await response.Content.ReadFromJsonAsync<BoardGetDTO>();
    Assert.NotNull(board);
    Assert.Equal(createdBoard.Id, board.Id);
    Assert.Equal("Test Board", board.Name);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task GetBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/non-existent-id");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task GetBoard_ReturnsForbidden_WhenAccessingAnotherUsersBoard()
  {
    var username1 = _utilities.GenerateUniqueUsername();
    var (signUpStatus1, loginData1) = await _utilities.SignUpUserAsync(username1, "password1", "User One");
    Assert.Equal(HttpStatusCode.OK, signUpStatus1);

    var username2 = _utilities.GenerateUniqueUsername();
    var (signUpStatus2, loginData2) = await _utilities.SignUpUserAsync(username2, "password2", "User Two");
    Assert.Equal(HttpStatusCode.OK, signUpStatus2);

    var board = await CreateTestBoard(loginData1!, "User 1 Board");

    // Try to access user 1's board with user 2's token
    var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{board.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData2!.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode); // Returns NotFound for security

    await _utilities.DeleteUserAsync(loginData1!.userId, loginData1.Token);
    await _utilities.DeleteUserAsync(loginData2!.userId, loginData2.Token);
  }

  [Fact]
  public async Task GetBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/some-board-id");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task PostBoard_ReturnsCreated_WithValidData()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var boardPostDTO = new BoardPostDTO
    {
      Name = "New Board",
      SnapshotPath = "/snapshots/test.jpg"
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Created, response.StatusCode);

    var board = await response.Content.ReadFromJsonAsync<BoardGetDTO>();
    Assert.NotNull(board);
    Assert.Equal("New Board", board.Name);
    Assert.NotNull(board.Id);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task PostBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var boardPostDTO = new BoardPostDTO
    {
      Name = "New Board"
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task PatchBoard_ReturnsNoContent_WithValidData()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var board = await CreateTestBoard(loginData, "Original Name");

    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = board.Id,
      Name = "Updated Name",
      SnapshotPath = "/snapshots/updated.jpg"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

    // Verify the update
    var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{board.Id}");
    getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
    var getResponse = await _client.SendAsync(getRequest);
    var updatedBoard = await getResponse.Content.ReadFromJsonAsync<BoardGetDTO>();

    Assert.NotNull(updatedBoard);
    Assert.Equal("Updated Name", updatedBoard.Name);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task PatchBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = "non-existent-id",
      Name = "Updated Name"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task PatchBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var boardPatchDTO = new BoardPatchDTO
    {
      BoardId = "some-board-id",
      Name = "Updated Name"
    };

    var request = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPatchDTO)
    };

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  [Fact]
  public async Task DeleteBoard_ReturnsNoContent_WithValidBoardId()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var board = await CreateTestBoard(loginData, "Board to Delete");

    var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Boards/{board.Id}");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

    // Verify deletion
    var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{board.Id}");
    getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
    var getResponse = await _client.SendAsync(getRequest);
    Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task DeleteBoard_ReturnsNotFound_WithInvalidBoardId()
  {
    var username = _utilities.GenerateUniqueUsername();
    var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
    Assert.Equal(HttpStatusCode.OK, signUpStatus);
    Assert.NotNull(loginData);

    var request = new HttpRequestMessage(HttpMethod.Delete, "/api/Users/Boards/non-existent-id");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

    await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
  }

  [Fact]
  public async Task DeleteBoard_WithoutAuthorization_ReturnsUnauthorized()
  {
    var request = new HttpRequestMessage(HttpMethod.Delete, "/api/Users/Boards/some-board-id");
    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
  }

  private async Task<BoardGetDTO> CreateTestBoard(UserLoginResponseDTO loginData, string boardName)
  {
    var boardPostDTO = new BoardPostDTO
    {
      Name = boardName
    };

    var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards")
    {
      Content = JsonContent.Create(boardPostDTO)
    };
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

    var response = await _client.SendAsync(request);
    Assert.Equal(HttpStatusCode.Created, response.StatusCode);

    var board = await response.Content.ReadFromJsonAsync<BoardGetDTO>();
    Assert.NotNull(board);

    return board;
  }
}