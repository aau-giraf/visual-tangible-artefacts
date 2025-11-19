using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class BoardControllerTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly Utilities _utilities;

    public BoardControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        _utilities = new Utilities(_client);
    }

    [Fact]
    public async Task Test_SaveAndUpdate_DuplicateArtefactInstances_OnBoard()
    {
        // Arrange: create user and login
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, loginData) = await _utilities.SignUpUserAsync(username, "testpassword", "Board Tester");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        Assert.NotNull(loginData);

        var token = loginData!.Token;

        // Create two artefacts (same base artefact can be reused by id but here create two distinct artefacts to simulate duplicates)
        var artefactIds = new List<string>();
        for (int i = 0; i < 2; i++)
        {
            var content = new MultipartFormDataContent();
            var imageContent = new ByteArrayContent(await File.ReadAllBytesAsync("IntegrationTests/TestData/testImage"));
            imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
            content.Add(imageContent, "Image", "testImage.jpg");
            content.Add(new StringContent(loginData.userId), "UserId");
            content.Add(new StringContent(i.ToString()), "ArtefactIndex");
            content.Add(new StringContent("Test Artefact"), "Name");

            var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Artefacts") { Content = content };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var response = await _client.SendAsync(request);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            var created = await JsonSerializer.DeserializeAsync<ArtefactGetDTO>(await response.Content.ReadAsStreamAsync(), options);
            Assert.NotNull(created);
            artefactIds.Add(created!.ArtefactId);
        }

        // For the purpose of duplicates, we'll use the same artefactId for both placements on the board
        var duplicateArtefactId = artefactIds[0];

        // Create a board with two instances of the same artefact but different positions/sizes
        var saveBody = new
        {
            name = "Test Board Duplicates",
            artefacts = new[]
            {
                new { artefactId = duplicateArtefactId, posX = 100.0f, posY = 100.0f, width = 150.0f, height = 150.0f },
                new { artefactId = duplicateArtefactId, posX = 300.0f, posY = 300.0f, width = 200.0f, height = 200.0f }
            }
        };

        var saveRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Boards")
        {
            Content = JsonContent.Create(saveBody)
        };
        saveRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var saveResponse = await _client.SendAsync(saveRequest);
        Assert.Equal(HttpStatusCode.Created, saveResponse.StatusCode);

        var opts = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var board = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(await saveResponse.Content.ReadAsStreamAsync(), opts);
        Assert.NotNull(board);
        Assert.Equal(2, board!.Artefacts.Count);
        // Each returned artefact should include a savedArtefactId
        Assert.All(board.Artefacts, a => Assert.False(string.IsNullOrEmpty(a.SavedArtefactId)));

        var boardId = board.BoardId;

        // Act: update both saved artefact instances via PATCH using savedArtefactId
        var updated1 = new { savedArtefactId = board.Artefacts[0].SavedArtefactId, artefactId = duplicateArtefactId, posX = 111.0f, posY = 111.0f, width = 160.0f, height = 160.0f };
        var updated2 = new { savedArtefactId = board.Artefacts[1].SavedArtefactId, artefactId = duplicateArtefactId, posX = 333.0f, posY = 333.0f, width = 220.0f, height = 220.0f };

        // Send updates sequentially
        var patchReq1 = new HttpRequestMessage(HttpMethod.Patch, $"/api/Users/Boards/{boardId}/artefacts") { Content = JsonContent.Create(updated1) };
        patchReq1.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var patchResp1 = await _client.SendAsync(patchReq1);
        Assert.Equal(HttpStatusCode.OK, patchResp1.StatusCode);

        var patchReq2 = new HttpRequestMessage(HttpMethod.Patch, $"/api/Users/Boards/{boardId}/artefacts") { Content = JsonContent.Create(updated2) };
        patchReq2.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var patchResp2 = await _client.SendAsync(patchReq2);
        Assert.Equal(HttpStatusCode.OK, patchResp2.StatusCode);

        // Assert: GET board should reflect both updated positions/sizes
        var getReq = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Boards/{boardId}");
        getReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var getResp = await _client.SendAsync(getReq);
        Assert.Equal(HttpStatusCode.OK, getResp.StatusCode);

        var gotBoard = await JsonSerializer.DeserializeAsync<BoardLayoutResponseDTO>(await getResp.Content.ReadAsStreamAsync(), opts);
        Assert.NotNull(gotBoard);
        Assert.Equal(2, gotBoard!.Artefacts.Count);

        // Find artefacts by saved id and verify positions
        var a1 = gotBoard.Artefacts.First(a => a.SavedArtefactId == board.Artefacts[0].SavedArtefactId);
        var a2 = gotBoard.Artefacts.First(a => a.SavedArtefactId == board.Artefacts[1].SavedArtefactId);

        Assert.Equal(111.0f, a1.PosX);
        Assert.Equal(111.0f, a1.PosY);
        Assert.Equal(160.0f, a1.Width);
        Assert.Equal(160.0f, a1.Height);

        Assert.Equal(333.0f, a2.PosX);
        Assert.Equal(333.0f, a2.PosY);
        Assert.Equal(220.0f, a2.Width);
        Assert.Equal(220.0f, a2.Height);

        // Cleanup: delete user (cascades)
        await _utilities.DeleteUserWithTokenAsync();
    }
}

// DTO used for test deserialization
internal class BoardLayoutResponseDTO
{
    public string BoardId { get; set; } = default!;
    public string Name { get; set; } = default!;
    public DateTime CreatedDate { get; set; }
    public DateTime? ModifiedDate { get; set; }
    public List<BoardArtefactDTO> Artefacts { get; set; } = new();
}

internal class BoardArtefactDTO
{
    public string? SavedArtefactId { get; set; }
    public string ArtefactId { get; set; } = default!;
    public float PosX { get; set; }
    public float PosY { get; set; }
    public float Width { get; set; }
    public float Height { get; set; }
}
