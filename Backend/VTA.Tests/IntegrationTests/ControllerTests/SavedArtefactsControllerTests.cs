using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class SavedArtefactsControllerTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly Utilities _utilities;

    public SavedArtefactsControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        _utilities = new Utilities(_client);
    }

    [Fact]
    public async Task GetSavedArtefacts_ReturnsOk_WithEmptyList()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");

        var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{board.Id}/Artefacts");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var savedArtefacts = await response.Content.ReadFromJsonAsync<List<SavedArtefactGetDTO>>();
        Assert.NotNull(savedArtefacts);
        Assert.Empty(savedArtefacts);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task GetSavedArtefacts_ReturnsOk_WithMultipleArtefacts()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact1 = await CreateTestArtefact(loginData);
        var artefact2 = await CreateTestArtefact(loginData);

        await AddArtefactToBoard(loginData, board.Id, artefact1.ArtefactId, 10, 20);
        await AddArtefactToBoard(loginData, board.Id, artefact2.ArtefactId, 30, 40);

        var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{board.Id}/Artefacts");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var savedArtefacts = await response.Content.ReadFromJsonAsync<List<SavedArtefactGetDTO>>();
        Assert.NotNull(savedArtefacts);
        Assert.Equal(2, savedArtefacts.Count);

        await CleanupArtefacts(loginData, new[] { artefact1, artefact2 });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task GetSavedArtefacts_ReturnsNotFound_WithInvalidBoardId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/non-existent-id/Artefacts");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task GetSavedArtefacts_WithoutAuthorization_ReturnsUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Boards/some-board-id/Artefacts");
        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetSavedArtefact_ReturnsOk_WithValidIds()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);
        var savedArtefact = await AddArtefactToBoard(loginData, board.Id, artefact.ArtefactId, 50, 60);

        var request = new HttpRequestMessage(HttpMethod.Get, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var retrievedArtefact = await response.Content.ReadFromJsonAsync<SavedArtefactGetDTO>();
        Assert.NotNull(retrievedArtefact);
        Assert.Equal(savedArtefact.Id, retrievedArtefact.Id);
        Assert.Equal(50, retrievedArtefact.PosX);
        Assert.Equal(60, retrievedArtefact.PosY);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task GetSavedArtefact_ReturnsNotFound_WithInvalidSavedArtefactId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");

        var request = new HttpRequestMessage(HttpMethod.Get, 
            $"/api/Users/Boards/{board.Id}/Artefacts/non-existent-id");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task GetSavedArtefact_WithoutAuthorization_ReturnsUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Get, 
            "/api/Users/Boards/some-board-id/Artefacts/some-artefact-id");
        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task PostSavedArtefact_ReturnsCreated_WithValidData()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);

        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = artefact.ArtefactId,
            PosX = 100,
            PosY = 200
        };

        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Users/Boards/{board.Id}/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var savedArtefact = await response.Content.ReadFromJsonAsync<SavedArtefactGetDTO>();
        Assert.NotNull(savedArtefact);
        Assert.Equal(artefact.ArtefactId, savedArtefact.ArtefactId);
        Assert.Equal(100, savedArtefact.PosX);
        Assert.Equal(200, savedArtefact.PosY);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PostSavedArtefact_ReturnsNotFound_WithInvalidBoardId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var artefact = await CreateTestArtefact(loginData);

        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = artefact.ArtefactId,
            PosX = 100,
            PosY = 200
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards/non-existent-id/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PostSavedArtefact_ReturnsNotFound_WithInvalidArtefactId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");

        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = "non-existent-artefact-id",
            PosX = 100,
            PosY = 200
        };

        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Users/Boards/{board.Id}/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PostSavedArtefact_ReturnsConflict_WhenArtefactAlreadyOnBoard()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);
        await AddArtefactToBoard(loginData, board.Id, artefact.ArtefactId, 10, 20);

        // Try to add the same artefact again
        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = artefact.ArtefactId,
            PosX = 30,
            PosY = 40
        };

        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Users/Boards/{board.Id}/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PostSavedArtefact_WithoutAuthorization_ReturnsUnauthorized()
    {
        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = "some-artefact-id",
            PosX = 100,
            PosY = 200
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards/some-board-id/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task PatchSavedArtefact_ReturnsNoContent_WithValidData()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);
        var savedArtefact = await AddArtefactToBoard(loginData, board.Id, artefact.ArtefactId, 10, 20);

        var savedArtefactPatchDTO = new SavedArtefactPatchDTO
        {
            SavedArtefactId = savedArtefact.Id,
            PosX = 150,
            PosY = 250
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}")
        {
            Content = JsonContent.Create(savedArtefactPatchDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the update
        var getRequest = new HttpRequestMessage(HttpMethod.Get, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        var updatedArtefact = await getResponse.Content.ReadFromJsonAsync<SavedArtefactGetDTO>();

        Assert.NotNull(updatedArtefact);
        Assert.Equal(150, updatedArtefact.PosX);
        Assert.Equal(250, updatedArtefact.PosY);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PatchSavedArtefact_ReturnsBadRequest_WhenIdMismatch()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);
        var savedArtefact = await AddArtefactToBoard(loginData, board.Id, artefact.ArtefactId, 10, 20);

        var savedArtefactPatchDTO = new SavedArtefactPatchDTO
        {
            SavedArtefactId = "different-id",
            PosX = 150,
            PosY = 250
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}")
        {
            Content = JsonContent.Create(savedArtefactPatchDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PatchSavedArtefact_ReturnsNotFound_WithInvalidSavedArtefactId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");

        var savedArtefactPatchDTO = new SavedArtefactPatchDTO
        {
            SavedArtefactId = "non-existent-id",
            PosX = 150,
            PosY = 250
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, 
            $"/api/Users/Boards/{board.Id}/Artefacts/non-existent-id")
        {
            Content = JsonContent.Create(savedArtefactPatchDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task PatchSavedArtefact_WithoutAuthorization_ReturnsUnauthorized()
    {
        var savedArtefactPatchDTO = new SavedArtefactPatchDTO
        {
            SavedArtefactId = "some-id",
            PosX = 150,
            PosY = 250
        };

        var request = new HttpRequestMessage(HttpMethod.Patch, 
            "/api/Users/Boards/some-board-id/Artefacts/some-id")
        {
            Content = JsonContent.Create(savedArtefactPatchDTO)
        };

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task DeleteSavedArtefact_ReturnsNoContent_WithValidIds()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");
        var artefact = await CreateTestArtefact(loginData);
        var savedArtefact = await AddArtefactToBoard(loginData, board.Id, artefact.ArtefactId, 10, 20);

        var request = new HttpRequestMessage(HttpMethod.Delete, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify deletion
        var getRequest = new HttpRequestMessage(HttpMethod.Get, 
            $"/api/Users/Boards/{board.Id}/Artefacts/{savedArtefact.Id}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);

        await CleanupArtefacts(loginData, new[] { artefact });
        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task DeleteSavedArtefact_ReturnsNotFound_WithInvalidSavedArtefactId()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var board = await CreateTestBoard(loginData, "Test Board");

        var request = new HttpRequestMessage(HttpMethod.Delete, 
            $"/api/Users/Boards/{board.Id}/Artefacts/non-existent-id");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        await _utilities.DeleteUserAsync(loginData.userId, loginData.Token);
    }

    [Fact]
    public async Task DeleteSavedArtefact_WithoutAuthorization_ReturnsUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, 
            "/api/Users/Boards/some-board-id/Artefacts/some-id");
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

    private async Task<ArtefactGetDTO> CreateTestArtefact(UserLoginResponseDTO loginData)
    {
        var content = new MultipartFormDataContent();
        var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
        imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(imageContent, "Image", "testImage.jpg");
        content.Add(new StringContent(loginData.userId), "UserId");
        content.Add(new StringContent("0"), "ArtefactIndex");
        content.Add(new StringContent("Test Artefact"), "Name");

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
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
        return artefact;
    }

    private async Task<SavedArtefactGetDTO> AddArtefactToBoard(UserLoginResponseDTO loginData, 
        string boardId, string artefactId, float posX, float posY)
    {
        var savedArtefactPostDTO = new SavedArtefactPostDTO
        {
            ArtefactId = artefactId,
            PosX = posX,
            PosY = posY
        };

        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Users/Boards/{boardId}/Artefacts")
        {
            Content = JsonContent.Create(savedArtefactPostDTO)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var savedArtefact = await response.Content.ReadFromJsonAsync<SavedArtefactGetDTO>();
        Assert.NotNull(savedArtefact);

        return savedArtefact;
    }

    private async Task CleanupArtefacts(UserLoginResponseDTO loginData, IEnumerable<ArtefactGetDTO> artefacts)
    {
        foreach (var artefact in artefacts)
        {
            var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Artefacts/{artefact.ArtefactId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            await _client.SendAsync(request);

            var assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", 
                loginData.userId, $"image_{artefact.ArtefactId}.jpg");
            if (File.Exists(assetsPath))
            {
                File.Delete(assetsPath);
            }
        }
    }
}