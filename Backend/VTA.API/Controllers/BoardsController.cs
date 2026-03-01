using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VTA.API.DTOs;
using VTA.API.Services;
using System.Text.Json;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing boards that belong to the authenticated user.
/// Provides endpoints to list, retrieve, create, update and delete saved boards.
/// </summary>
[Authorize]
[Route("api/Boards")]
[ApiController]
public class BoardsController : ControllerBase
{
  private readonly IBoardService _boardService;

  /// <summary>
  /// Initializes a new instance of the <see cref="BoardsController"/> class.
  /// </summary>
  /// <param name="boardService">The <see cref="IBoardService"/> used to manage boards and artefacts.</param>
  public BoardsController(IBoardService boardService)
  {
    _boardService = boardService;
  }

  // GET: api/Boards
  /// <summary>
  /// Gets all boards that the authenticated user owns
  /// </summary>
  /// <param name="skip">Number of items to skip (pagination)</param>
  /// <param name="take">Number of items to return (pagination, default 50)</param>
  /// <returns>A collection of boards with their saved artefacts</returns>
  [HttpGet]
  public async Task<ActionResult<IEnumerable<BoardGetDTO>>> GetBoards([FromQuery] int? skip, [FromQuery] int? take)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    var boards = await _boardService.GetBoardsForUserAsync(userId, skip, take);

    var boardDTOs = boards.Select(board => new BoardGetDTO
    {
      Id = board.Id,
      Name = board.Name,
      SnapshotUrl = string.IsNullOrEmpty(board.SnapshotPath) ? null : $"{Request.Scheme}://{Request.Host}{board.SnapshotPath}",
      CreatedDate = board.CreatedDate,
      ModifiedDate = board.ModifiedDate
    }).ToList();

    return Ok(boardDTOs);
  }

  // GET: api/Boards/list
  /// <summary>
  /// Gets a lightweight list of board IDs, names, and thumbnails for the authenticated user
  /// </summary>
  /// <param name="skip">Number of items to skip (pagination)</param>
  /// <param name="take">Number of items to return (pagination, default 50)</param>
  /// <returns>A collection of minimal board information</returns>
  [HttpGet("list")]
  public async Task<ActionResult<IEnumerable<BoardListItemDTO>>> GetBoardsList([FromQuery] int? skip, [FromQuery] int? take)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    var boards = await _boardService.GetBoardListAsync(userId, skip, take);

    var boardListItems = boards.Select(board => new BoardListItemDTO
    {
      Id = board.Id,
      Name = board.Name,
      SnapshotUrl = string.IsNullOrEmpty(board.SnapshotPath) ? null : $"{Request.Scheme}://{Request.Host}{board.SnapshotPath}"
    }).ToList();

    return Ok(boardListItems);
  }

  // GET: api/Boards/{boardId}
  /// <summary>
  /// Gets a specific board with all its saved artefacts
  /// </summary>
  /// <param name="boardId">The board ID</param>
  /// <returns>The specified board with all saved artefacts</returns>
  [HttpGet("{boardId}")]
  public async Task<ActionResult<BoardGetDTO>> GetBoard(string boardId)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    var board = await _boardService.GetBoardAsync(boardId, userId);
    if (board == null) return NotFound();

    var response = new BoardLayoutResponseDTO
    {
      BoardId = board.Id,
      Name = board.Name,
      CreatedDate = board.CreatedDate,
      ModifiedDate = board.ModifiedDate,
      Artefacts = board.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
      {
        SavedArtefactId = sa.Id,
        ArtefactId = sa.ArtefactId,
        PosX = sa.PosX,
        PosY = sa.PosY,
        Width = sa.Width,
        Height = sa.Height
      }).ToList()
    };

    return Ok(response);
  }

  // POST: api/Boards
  /// <summary>
  /// Creates a new board for the authenticated user. Accepts either the simple
  /// `BoardPostDTO` shape or the richer `SaveBoardRequestDTO` with artefact layouts.
  /// </summary>
  /// <param name="body">Raw JSON body to support multiple DTO shapes.</param>
  /// <returns>The created board</returns>
  [HttpPost]
  public async Task<IActionResult> PostBoard([FromBody] JsonElement body)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    // If the JSON contains an "Artefacts" property, treat as SaveBoardRequestDTO
    if (body.ValueKind == JsonValueKind.Object && body.EnumerateObject().Any(p => string.Equals(p.Name, "Artefacts", StringComparison.OrdinalIgnoreCase)))
    {
      var request = JsonSerializer.Deserialize<SaveBoardRequestDTO>(body.GetRawText(), new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

      if (request == null || string.IsNullOrWhiteSpace(request.Name))
      {
        return BadRequest("Board name is required");
      }

      try
      {
        var created = await _boardService.CreateBoardAsync(userId, request.Name, request.Artefacts);

        var response = new BoardLayoutResponseDTO
        {
          BoardId = created.Id,
          Name = created.Name,
          CreatedDate = created.CreatedDate,
          ModifiedDate = created.ModifiedDate,
          Artefacts = created.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
          {
            SavedArtefactId = sa.Id,
            ArtefactId = sa.ArtefactId,
            PosX = sa.PosX,
            PosY = sa.PosY,
            Width = sa.Width,
            Height = sa.Height
          }).ToList()
        };

        return CreatedAtAction(nameof(GetBoard), new { boardId = response.BoardId }, response);
      }
      catch (InvalidOperationException)
      {
        return BadRequest("Artefact not found or doesn't belong to user");
      }
    }

    // Fallback: simple BoardPostDTO
    var boardPost = JsonSerializer.Deserialize<BoardPostDTO>(body.GetRawText(), new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
    if (boardPost == null) return BadRequest();

    var createdBoard = await _boardService.CreateBoardAsync(userId, boardPost.Name);

    var boardDTO = new
    {
      createdBoard.Id,
      createdBoard.Name,
      createdBoard.SnapshotPath,
      createdBoard.CreatedDate,
      createdBoard.ModifiedDate
    };

    return Ok(boardDTO);
  }

  // PATCH: api/Boards
  /// <summary>
  /// Updates a board's information
  /// </summary>
  /// <param name="boardPatchDTO">Board update data</param>
  /// <returns>No content on success</returns>
  [HttpPatch]
  public async Task<IActionResult> PatchBoard([FromBody] BoardPatchDTO boardPatchDTO)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    var success = await _boardService.PatchBoardAsync(
        boardPatchDTO.BoardId, userId, boardPatchDTO.Name, boardPatchDTO.SnapshotPath);

    return success ? NoContent() : NotFound();
  }

  // PUT: api/Boards/{boardId}
  /// <summary>
  /// Update an existing board layout (name and artefacts). Uses SaveBoardRequestDTO format.
  /// </summary>
  [HttpPut("{boardId}")]
  public async Task<ActionResult<BoardLayoutResponseDTO>> UpdateBoard(string boardId, [FromBody] SaveBoardRequestDTO request)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized("Invalid token");

    try
    {
      var board = await _boardService.UpdateBoardAsync(boardId, userId, request.Name, request.Artefacts);

      if (board == null) return NotFound("Board not found");

      var response = new BoardLayoutResponseDTO
      {
        BoardId = board.Id,
        Name = board.Name,
        CreatedDate = board.CreatedDate,
        ModifiedDate = board.ModifiedDate,
        Artefacts = board.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
        {
          SavedArtefactId = sa.Id,
          ArtefactId = sa.ArtefactId,
          PosX = sa.PosX,
          PosY = sa.PosY,
          Width = sa.Width,
          Height = sa.Height
        }).ToList()
      };

      return Ok(response);
    }
    catch (InvalidOperationException)
    {
      return BadRequest("Artefact not found or doesn't belong to user");
    }
    catch (Exception ex)
    {
      if (ex.Message.Contains("Unknown column") || ex.Message.Contains("width") || ex.Message.Contains("height"))
      {
        return StatusCode(500, "Database schema needs migration. Please run the migration endpoint first.");
      }
      return StatusCode(500, "Error updating board");
    }
  }

  // PATCH: api/Boards/{boardId}/artefacts
  /// <summary>
  /// Update the position and size of a specific artefact on a board
  /// </summary>
  [HttpPatch("{boardId}/artefacts")]
  public async Task<IActionResult> UpdateArtefactLayout(string boardId, [FromBody] UpdateArtefactLayoutDTO request)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized("Invalid token");

    var (success, error) = await _boardService.UpdateArtefactLayoutAsync(boardId, userId, request);

    return error switch
    {
      "NotFound" => NotFound("Board not found"),
      "BadRequest" => BadRequest("Artefact not found or doesn't belong to user"),
      _ when success => Ok(new { message = "Artefact layout updated successfully" }),
      _ => StatusCode(500, "Error updating artefact layout")
    };
  }

  // DELETE: api/Boards/{boardId}/artefacts/{savedArtefactId}
  /// <summary>
  /// Remove a specific artefact from a board
  /// </summary>
  [HttpDelete("{boardId}/artefacts/{savedArtefactId}")]
  public async Task<IActionResult> RemoveArtefactFromBoard(string boardId, string savedArtefactId)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized("Invalid token");

    var (success, error) = await _boardService.RemoveArtefactFromBoardAsync(boardId, savedArtefactId, userId);

    if (!success)
    {
      return error == "NotFound" ? NotFound("Board or saved artefact not found") : StatusCode(500);
    }

    return NoContent();
  }

  // DELETE: api/Boards/{boardId}/artefacts
  /// <summary>
  /// Clear all artefacts from a board (without deleting the board itself)
  /// </summary>
  [HttpDelete("{boardId}/artefacts")]
  public async Task<IActionResult> ClearBoard(string boardId)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized("Invalid token");

    var (success, error) = await _boardService.ClearBoardAsync(boardId, userId);

    if (!success) return NotFound("Board not found");

    return Ok(new { message = "Board cleared successfully" });
  }

  // DELETE: api/Boards/{boardId}
  /// <summary>
  /// Deletes a board and all its saved artefacts
  /// </summary>
  /// <param name="boardId">The board ID</param>
  /// <returns>No content on success</returns>
  [HttpDelete("{boardId}")]
  public async Task<IActionResult> DeleteBoard(string boardId)
  {
    var sub = User.FindFirst("sub")?.Value;
    if (!int.TryParse(sub, out var userId)) return Unauthorized();

    var (success, _) = await _boardService.DeleteBoardAsync(boardId, userId);

    return success ? NoContent() : NotFound();
  }
}