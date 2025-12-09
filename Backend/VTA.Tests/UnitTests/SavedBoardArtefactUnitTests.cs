using VTA.API.Models;
using VTA.API.DTOs;
using System.Text.Json;

namespace VTA.Tests.UnitTests;

/// <summary>
/// Unit tests for SavedBoard and SavedArtefact models
/// Tests the business logic and data validation without database dependencies
/// </summary>
public class SavedBoardArtefactUnitTests
{
    [Fact]
    public void SavedBoard_Creation_ShouldSetDefaultValues()
    {
        // Arrange & Act
        var board = new SavedBoard
        {
            Id = "test-id",
            Name = "Test Board",
            UserId = "user-123"
        };

        // Assert
        Assert.Equal("test-id", board.Id);
        Assert.Equal("Test Board", board.Name);
        Assert.Equal("user-123", board.UserId);
        Assert.Null(board.SnapshotPath);
        Assert.True(board.CreatedDate <= DateTime.UtcNow);
        Assert.True(board.CreatedDate > DateTime.UtcNow.AddMinutes(-1)); // Created within last minute
        Assert.Null(board.ModifiedDate);
        Assert.NotNull(board.SavedArtefacts);
        Assert.Empty(board.SavedArtefacts);
    }

    [Fact]
    public void SavedArtefact_Creation_ShouldSetDefaultValues()
    {
        // Arrange & Act
        var savedArtefact = new SavedArtefact
        {
            Id = "saved-id",
            ArtefactId = "artefact-123",
            BoardId = "board-456"
        };

        // Assert
        Assert.Equal("saved-id", savedArtefact.Id);
        Assert.Equal("artefact-123", savedArtefact.ArtefactId);
        Assert.Equal("board-456", savedArtefact.BoardId);
        Assert.Equal(0, savedArtefact.PosX);
        Assert.Equal(0, savedArtefact.PosY);
        Assert.Equal(200, savedArtefact.Width);
        Assert.Equal(200, savedArtefact.Height);
        Assert.True(savedArtefact.CreatedDate <= DateTime.UtcNow);
        Assert.True(savedArtefact.CreatedDate > DateTime.UtcNow.AddMinutes(-1));
    }

    [Fact]
    public void SavedArtefact_CustomPositionAndSize_ShouldSetCorrectly()
    {
        // Arrange & Act
        var savedArtefact = new SavedArtefact
        {
            Id = "saved-id",
            ArtefactId = "artefact-123",
            BoardId = "board-456",
            PosX = 150.5f,
            PosY = 300.7f,
            Width = 250.3f,
            Height = 180.9f
        };

        // Assert
        Assert.Equal(150.5f, savedArtefact.PosX);
        Assert.Equal(300.7f, savedArtefact.PosY);
        Assert.Equal(250.3f, savedArtefact.Width);
        Assert.Equal(180.9f, savedArtefact.Height);
    }

    [Theory]
    [InlineData(-100.0f, 50.0f, 200.0f, 200.0f)] // Negative X position
    [InlineData(50.0f, -100.0f, 200.0f, 200.0f)] // Negative Y position
    [InlineData(50.0f, 50.0f, 0.0f, 200.0f)]     // Zero width
    [InlineData(50.0f, 50.0f, 200.0f, 0.0f)]     // Zero height
    [InlineData(50.0f, 50.0f, -50.0f, 200.0f)]   // Negative width
    [InlineData(50.0f, 50.0f, 200.0f, -50.0f)]   // Negative height
    public void SavedArtefact_EdgeCasePositionsAndSizes_ShouldAcceptAnyFloatValues(float posX, float posY, float width, float height)
    {
        // Arrange & Act - The model should accept any float values (validation should be in DTOs/Controllers if needed)
        var savedArtefact = new SavedArtefact
        {
            Id = "saved-id",
            ArtefactId = "artefact-123",
            BoardId = "board-456",
            PosX = posX,
            PosY = posY,
            Width = width,
            Height = height
        };

        // Assert - Model should store whatever values are provided
        Assert.Equal(posX, savedArtefact.PosX);
        Assert.Equal(posY, savedArtefact.PosY);
        Assert.Equal(width, savedArtefact.Width);
        Assert.Equal(height, savedArtefact.Height);
    }

    [Fact]
    public void SavedBoard_ArtefactIdsSerialization_ShouldWorkCorrectly()
    {
        // Arrange
        var board = new SavedBoard
        {
            Id = "board-id",
            Name = "Test Board",
            UserId = "user-123"
        };

        var artefactIds = new List<string> { "art-1", "art-2", "art-3" };
        var savedArtefactIds = new List<string> { "saved-1", "saved-2", "saved-3" };

        // Act
        board.ArtefactIds = JsonSerializer.Serialize(artefactIds);
        board.SavedArtefactIds = JsonSerializer.Serialize(savedArtefactIds);

        // Assert
        Assert.NotNull(board.ArtefactIds);
        Assert.NotNull(board.SavedArtefactIds);

        var deserializedArtefactIds = JsonSerializer.Deserialize<List<string>>(board.ArtefactIds);
        var deserializedSavedArtefactIds = JsonSerializer.Deserialize<List<string>>(board.SavedArtefactIds);

        Assert.NotNull(deserializedArtefactIds);
        Assert.NotNull(deserializedSavedArtefactIds);
        Assert.Equal(artefactIds, deserializedArtefactIds);
        Assert.Equal(savedArtefactIds, deserializedSavedArtefactIds);
    }

    [Fact]
    public void SavedBoard_EmptyArtefactLists_ShouldBeNull()
    {
        // Arrange
        var board = new SavedBoard
        {
            Id = "board-id",
            Name = "Empty Board",
            UserId = "user-123"
        };

        var emptyList = new List<string>();

        // Act - When there are no artefacts, the JSON arrays should be null
        board.ArtefactIds = emptyList.Count > 0 ? JsonSerializer.Serialize(emptyList) : null;
        board.SavedArtefactIds = emptyList.Count > 0 ? JsonSerializer.Serialize(emptyList) : null;

        // Assert
        Assert.Null(board.ArtefactIds);
        Assert.Null(board.SavedArtefactIds);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void SavedBoard_InvalidName_ShouldStillAllowCreation(string invalidName)
    {
        // Arrange & Act - Model itself doesn't validate, validation should be in DTOs/Controllers
        var board = new SavedBoard
        {
            Id = "board-id",
            Name = invalidName!,  // The model accepts any string since it's marked as required
            UserId = "user-123"
        };

        // Assert - Model stores whatever is provided
        Assert.Equal(invalidName, board.Name);
    }

    [Fact]
    public void BoardArtefactLayoutDTO_DefaultValues_ShouldBeCorrect()
    {
        // Arrange & Act
        var dto = new BoardArtefactLayoutDTO
        {
            ArtefactId = "test-artefact"
        };

        // Assert
        Assert.Equal("test-artefact", dto.ArtefactId);
        Assert.Null(dto.SavedArtefactId);
        Assert.Equal(0, dto.PosX);
        Assert.Equal(0, dto.PosY);
        Assert.True(dto.Width == 200 || dto.Width == 0);
        Assert.True(dto.Height == 200 || dto.Height == 0);
    }

    [Fact]
    public void SaveBoardRequestDTO_EmptyArtefacts_ShouldBeValid()
    {
        // Arrange & Act
        var dto = new SaveBoardRequestDTO
        {
            Name = "Empty Board"
        };

        // Assert
        Assert.Equal("Empty Board", dto.Name);
        Assert.NotNull(dto.Artefacts);
        Assert.Empty(dto.Artefacts);
    }

    [Fact]
    public void UpdateArtefactLayoutDTO_AllProperties_ShouldSetCorrectly()
    {
        // Arrange & Act
        var dto = new UpdateArtefactLayoutDTO
        {
            SavedArtefactId = "saved-123",
            ArtefactId = "artefact-456",
            PosX = 123.4f,
            PosY = 567.8f,
            Width = 234.5f,
            Height = 345.6f
        };

        // Assert
        Assert.Equal("saved-123", dto.SavedArtefactId);
        Assert.Equal("artefact-456", dto.ArtefactId);
        Assert.Equal(123.4f, dto.PosX);
        Assert.Equal(567.8f, dto.PosY);
        Assert.Equal(234.5f, dto.Width);
        Assert.Equal(345.6f, dto.Height);
    }

    [Fact]
    public void BoardLayoutResponseDTO_MultipleArtefacts_ShouldMaintainOrder()
    {
        // Arrange
        var artefacts = new List<BoardArtefactLayoutDTO>
        {
            new() { ArtefactId = "art-1", SavedArtefactId = "saved-1", PosX = 100, PosY = 100 },
            new() { ArtefactId = "art-2", SavedArtefactId = "saved-2", PosX = 200, PosY = 200 },
            new() { ArtefactId = "art-3", SavedArtefactId = "saved-3", PosX = 300, PosY = 300 }
        };

        // Act
        var dto = new BoardLayoutResponseDTO
        {
            BoardId = "board-123",
            Name = "Test Board",
            CreatedDate = DateTime.UtcNow,
            Artefacts = artefacts
        };

        // Assert
        Assert.Equal(3, dto.Artefacts.Count);
        Assert.Equal("art-1", dto.Artefacts[0].ArtefactId);
        Assert.Equal("art-2", dto.Artefacts[1].ArtefactId);
        Assert.Equal("art-3", dto.Artefacts[2].ArtefactId);
        Assert.Equal(100, dto.Artefacts[0].PosX);
        Assert.Equal(200, dto.Artefacts[1].PosX);
        Assert.Equal(300, dto.Artefacts[2].PosX);
    }

    [Fact]
    public void SavedBoard_ModifiedDate_ShouldBeNullInitially()
    {
        // Arrange & Act
        var board = new SavedBoard
        {
            Id = "board-id",
            Name = "Test Board",
            UserId = "user-123"
        };

        // Assert
        Assert.Null(board.ModifiedDate);
        
        // Act - Simulate an update
        board.ModifiedDate = DateTime.UtcNow;
        
        // Assert
        Assert.NotNull(board.ModifiedDate);
        Assert.True(board.ModifiedDate <= DateTime.UtcNow);
    }

    [Fact]
    public void SavedBoard_MultipleArtefactInstances_ShouldTrackSeparately()
    {
        // Arrange
        var board = new SavedBoard
        {
            Id = "board-id",
            Name = "Multi-Instance Board",
            UserId = "user-123"
        };

        var savedArtefacts = new List<SavedArtefact>
        {
            new() { Id = "saved-1", ArtefactId = "art-1", BoardId = board.Id, PosX = 100, PosY = 100 },
            new() { Id = "saved-2", ArtefactId = "art-1", BoardId = board.Id, PosX = 300, PosY = 300 }, // Same artefact, different instance
            new() { Id = "saved-3", ArtefactId = "art-2", BoardId = board.Id, PosX = 500, PosY = 500 }
        };

        // Act
        board.SavedArtefacts = savedArtefacts;

        // Assert
        Assert.Equal(3, board.SavedArtefacts.Count);
        
        // Verify that we can have multiple instances of the same artefact
        var artefact1Instances = board.SavedArtefacts.Where(sa => sa.ArtefactId == "art-1").ToList();
        Assert.Equal(2, artefact1Instances.Count);
        Assert.Equal("saved-1", artefact1Instances[0].Id);
        Assert.Equal("saved-2", artefact1Instances[1].Id);
        
        // Verify different positions
        Assert.Equal(100, artefact1Instances[0].PosX);
        Assert.Equal(300, artefact1Instances[1].PosX);
    }

    [Fact]
    public void SavedArtefact_FloatPrecision_ShouldMaintainAccuracy()
    {
        // Arrange - Test floating point precision
        var preciseX = 123.456789f;
        var preciseY = 987.654321f;
        var preciseWidth = 456.123789f;
        var preciseHeight = 789.987654f;

        // Act
        var savedArtefact = new SavedArtefact
        {
            Id = "precision-test",
            ArtefactId = "art-precise",
            BoardId = "board-precise",
            PosX = preciseX,
            PosY = preciseY,
            Width = preciseWidth,
            Height = preciseHeight
        };

        // Assert - Values should be stored with float precision
        Assert.Equal(preciseX, savedArtefact.PosX, precision: 6);
        Assert.Equal(preciseY, savedArtefact.PosY, precision: 6);
        Assert.Equal(preciseWidth, savedArtefact.Width, precision: 6);
        Assert.Equal(preciseHeight, savedArtefact.Height, precision: 6);
    }
}