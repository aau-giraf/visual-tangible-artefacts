using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using System.Text.Json;
using VTA.Data.DbContexts;
using VTA.Data.Models;

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
  private readonly VTAContext _context;

  /// <summary>
  /// Initializes a new instance of the <see cref="BoardsController"/> class.
  /// </summary>
  /// <param name="context">The <see cref="VTAContext"/> used to access saved boards and artefacts.</param>
  public BoardsController(VTAContext context)
  {
    _context = context;
  }

  // GET: api/Boards
  /// <summary>
  /// Gets all boards that the authenticated user owns
  /// </summary>
  /// <returns>A collection of boards with their saved artefacts</returns>
  [HttpGet]
  public async Task<ActionResult<IEnumerable<BoardGetDTO>>> GetBoards()
  {
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    var boards = await _context.SavedBoards
        .Where(b => b.UserId == userId)
        .Include(b => b.SavedArtefacts)
            .ThenInclude(sa => sa.Artefact)
        .OrderByDescending(b => b.ModifiedDate ?? b.CreatedDate)
        .ToListAsync();

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
  /// <returns>A collection of minimal board information</returns>
  [HttpGet("list")]
  public async Task<ActionResult<IEnumerable<BoardListItemDTO>>> GetBoardsList()
  {
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    var boards = await _context.SavedBoards
        .Where(b => b.UserId == userId)
        .OrderByDescending(b => b.ModifiedDate ?? b.CreatedDate)
        .ToListAsync();

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
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardId && b.UserId == userId)
        .Include(b => b.SavedArtefacts)
            .ThenInclude(sa => sa.Artefact)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound();
    }

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
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    // If the JSON contains an "Artefacts" property (case-insensitive), treat it as SaveBoardRequestDTO
    if (body.ValueKind == JsonValueKind.Object && body.EnumerateObject().Any(p => string.Equals(p.Name, "Artefacts", StringComparison.OrdinalIgnoreCase)))
    {
      var request = JsonSerializer.Deserialize<SaveBoardRequestDTO>(body.GetRawText(), new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

      if (request == null || string.IsNullOrWhiteSpace(request.Name))
      {
        return BadRequest("Board name is required");
      }

      try
      {
        var strategy = _context.Database.CreateExecutionStrategy();
        var created = await strategy.ExecuteAsync<BoardLayoutResponseDTO>(async () =>
        {
          using var transaction = await _context.Database.BeginTransactionAsync();
          try
          {
            var board = new SavedBoard
            {
              Id = Guid.NewGuid().ToString(),
              Name = request.Name,
              UserId = userId,
              CreatedDate = DateTime.UtcNow
            };

            _context.SavedBoards.Add(board);
            await _context.SaveChangesAsync();

            var artefactIds = new List<string>();
            var savedArtefactIds = new List<string>();

            foreach (var artefactLayout in request.Artefacts)
            {
              var artefactExists = await _context.Artefacts
                  .AnyAsync(a => a.ArtefactId == artefactLayout.ArtefactId && a.UserId == userId);

              if (!artefactExists)
              {
                throw new InvalidOperationException($"Artefact {artefactLayout.ArtefactId} not found or doesn't belong to user");
              }

              // Preserve provided values, including zeros; clamp extremes to float bounds
              float Clamp(float v)
              {
                if (float.IsNaN(v) || float.IsInfinity(v)) return 0f;
                return v;
              }

              var savedArtefact = new SavedArtefact
              {
                Id = Guid.NewGuid().ToString(),
                ArtefactId = artefactLayout.ArtefactId,
                BoardId = board.Id,
                PosX = Clamp(artefactLayout.PosX),
                PosY = Clamp(artefactLayout.PosY),
                Width = Clamp(artefactLayout.Width),
                Height = Clamp(artefactLayout.Height),
                CreatedDate = DateTime.UtcNow
              };

              _context.SavedArtefacts.Add(savedArtefact);

              artefactIds.Add(artefactLayout.ArtefactId);
              savedArtefactIds.Add(savedArtefact.Id);
            }

            board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
            board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;

            _context.SavedBoards.Update(board);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            var createdBoard = await _context.SavedBoards
              .Where(b => b.Id == board.Id)
              .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
              .FirstOrDefaultAsync();

            // Return BoardLayoutResponseDTO to match frontend expectations (boardId + artefacts array)
            return new BoardLayoutResponseDTO
            {
              BoardId = createdBoard!.Id,
              Name = createdBoard.Name,
              CreatedDate = createdBoard.CreatedDate,
              ModifiedDate = createdBoard.ModifiedDate,
              Artefacts = createdBoard.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
              {
                SavedArtefactId = sa.Id,
                ArtefactId = sa.ArtefactId,
                PosX = sa.PosX,
                PosY = sa.PosY,
                Width = sa.Width,
                Height = sa.Height
              }).ToList()
            };
          }
          catch
          {
            await transaction.RollbackAsync();
            throw;
          }
        });
        return CreatedAtAction(nameof(GetBoard), new { boardId = created.BoardId }, created);
      }
      catch (InvalidOperationException ex)
      {
        Console.WriteLine($"Error saving board: {ex.Message}");
        return BadRequest("Artefact not found or doesn't belong to user");
      }
      // Let other exceptions bubble up to ensure proper error surfacing
    }

    // Fallback: treat as the original simple BoardPostDTO
    var boardPost = JsonSerializer.Deserialize<BoardPostDTO>(body.GetRawText(), new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

    if (boardPost == null)
    {
      return BadRequest();
    }

    var boardIdSimple = Guid.NewGuid().ToString();
    var boardSimple = new SavedBoard { Id = boardIdSimple, Name = boardPost.Name, UserId = userId };

    _context.SavedBoards.Add(boardSimple);
    await _context.SaveChangesAsync();

    var createdBoardSimple = await _context.SavedBoards
        .Include(b => b.SavedArtefacts)
            .ThenInclude(sa => sa.Artefact)
        .FirstOrDefaultAsync(b => b.Id == boardSimple.Id);

    if (createdBoardSimple == null)
    {
      return NotFound();
    }

    var boardDTO = new
    {
      createdBoardSimple.Id,
      createdBoardSimple.Name,
      createdBoardSimple.SnapshotPath,
      createdBoardSimple.CreatedDate,
      createdBoardSimple.ModifiedDate
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
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardPatchDTO.BoardId && b.UserId == userId)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound();
    }

    // Update fields if provided
    if (!string.IsNullOrEmpty(boardPatchDTO.Name))
    {
      board.Name = boardPatchDTO.Name;
    }

    if (boardPatchDTO.SnapshotPath != null)
    {
      board.SnapshotPath = boardPatchDTO.SnapshotPath;
    }

    board.ModifiedDate = DateTime.UtcNow;

    _context.Entry(board).State = EntityState.Modified;

    try
    {
      await _context.SaveChangesAsync();
    }
    catch (DbUpdateConcurrencyException)
    {
      if (!BoardExists(board.Id))
      {
        return NotFound();
      }
      else
      {
        throw;
      }
    }

    return NoContent();
  }

  // PUT: api/Boards/{boardId}
  /// <summary>
  /// Update an existing board layout (name and artefacts). Uses SaveBoardRequestDTO format.
  /// </summary>
  [HttpPut("{boardId}")]
  public async Task<ActionResult<BoardLayoutResponseDTO>> UpdateBoard(string boardId, [FromBody] SaveBoardRequestDTO request)
  {
    var userId = User.FindFirst("id")?.Value;
    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized("Invalid token");
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardId && b.UserId == userId)
        .Include(b => b.SavedArtefacts)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound("Board not found");
    }

    try
    {
      var strategy = _context.Database.CreateExecutionStrategy();
      var response = await strategy.ExecuteAsync(async () =>
      {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
          board.Name = request.Name;
          board.ModifiedDate = DateTime.UtcNow;

          var existingSavedArtefacts = board.SavedArtefacts.ToList();
          var newArtefactLayouts = request.Artefacts.ToList();

          // Do not remove or deduplicate based on identical layout; duplicates are allowed
          var artefactsToRemove = new List<SavedArtefact>();

          if (artefactsToRemove.Any())
          {
            _context.SavedArtefacts.RemoveRange(artefactsToRemove);
          }

          var artefactIds = new List<string>();
          var savedArtefactIds = new List<string>();

          var keptSavedArtefacts = existingSavedArtefacts.Except(artefactsToRemove).ToList();
          foreach (var keptArtefact in keptSavedArtefacts)
          {
            artefactIds.Add(keptArtefact.ArtefactId);
            savedArtefactIds.Add(keptArtefact.Id);
          }

          foreach (var artefactLayout in newArtefactLayouts)
          {

            var artefactExists = await _context.Artefacts
                .AnyAsync(a => a.ArtefactId == artefactLayout.ArtefactId && a.UserId == userId);

            if (!artefactExists)
            {
              throw new InvalidOperationException($"Artefact {artefactLayout.ArtefactId} not found or doesn't belong to user");
            }

            var savedArtefact = new SavedArtefact
            {
              Id = Guid.NewGuid().ToString(),
              ArtefactId = artefactLayout.ArtefactId,
              BoardId = board.Id,
              PosX = artefactLayout.PosX,
              PosY = artefactLayout.PosY,
              Width = artefactLayout.Width,
              Height = artefactLayout.Height,
              CreatedDate = DateTime.UtcNow
            };

            _context.SavedArtefacts.Add(savedArtefact);

            artefactIds.Add(artefactLayout.ArtefactId);
            savedArtefactIds.Add(savedArtefact.Id);
          }

          board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
          board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
          _context.SavedBoards.Update(board);

          await _context.SaveChangesAsync();
          await transaction.CommitAsync();

          var updatedBoard = await _context.SavedBoards
              .Where(b => b.Id == board.Id)
              .Include(b => b.SavedArtefacts)
              .FirstOrDefaultAsync();

          return new BoardLayoutResponseDTO
          {
            BoardId = updatedBoard!.Id,
            Name = updatedBoard.Name,
            CreatedDate = updatedBoard.CreatedDate,
            ModifiedDate = updatedBoard.ModifiedDate,
            Artefacts = updatedBoard.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
            {
              SavedArtefactId = sa.Id,
              ArtefactId = sa.ArtefactId,
              PosX = sa.PosX,
              PosY = sa.PosY,
              Width = sa.Width,
              Height = sa.Height
            }).ToList()
          };
        }
        catch
        {
          await transaction.RollbackAsync();
          throw;
        }
      });

      return Ok(response);
    }
    catch (Exception ex)
    {
      Console.WriteLine($"Error updating board: {ex.Message}");
      Console.WriteLine($"Stack trace: {ex.StackTrace}");
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
    var userId = User.FindFirst("id")?.Value;
    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized("Invalid token");
    }

    var boardExists = await _context.SavedBoards
        .AnyAsync(b => b.Id == boardId && b.UserId == userId);

    if (!boardExists)
    {
      return NotFound("Board not found");
    }

    SavedArtefact? savedArtefact = null;

    if (!string.IsNullOrEmpty(request.SavedArtefactId))
    {
      savedArtefact = await _context.SavedArtefacts
          .FirstOrDefaultAsync(sa => sa.Id == request.SavedArtefactId && sa.BoardId == boardId);
    }

    if (savedArtefact == null)
    {
      savedArtefact = await _context.SavedArtefacts
          .FirstOrDefaultAsync(sa => sa.BoardId == boardId && sa.ArtefactId == request.ArtefactId);
    }

    if (savedArtefact == null)
    {
      var artefactExists = await _context.Artefacts
          .AnyAsync(a => a.ArtefactId == request.ArtefactId && a.UserId == userId);

      if (!artefactExists)
      {
        return BadRequest("Artefact not found or doesn't belong to user");
      }

      savedArtefact = new SavedArtefact
      {
        Id = Guid.NewGuid().ToString(),
        ArtefactId = request.ArtefactId,
        BoardId = boardId,
        PosX = request.PosX,
        PosY = request.PosY,
        Width = request.Width,
        Height = request.Height,
        CreatedDate = DateTime.UtcNow
      };

      _context.SavedArtefacts.Add(savedArtefact);

      var boardForArtefactUpdate = await _context.SavedBoards.FindAsync(boardId);
      if (boardForArtefactUpdate != null)
      {
        var artefactIdsList = await _context.SavedArtefacts
            .Where(sa => sa.BoardId == boardId)
            .Select(sa => sa.ArtefactId)
            .ToListAsync();

        var savedInstanceIds = await _context.SavedArtefacts
            .Where(sa => sa.BoardId == boardId)
            .Select(sa => sa.Id)
            .ToListAsync();

        if (!artefactIdsList.Contains(savedArtefact.ArtefactId))
        {
          artefactIdsList.Add(savedArtefact.ArtefactId);
        }

        if (!savedInstanceIds.Contains(savedArtefact.Id))
        {
          savedInstanceIds.Add(savedArtefact.Id);
        }

        boardForArtefactUpdate.ArtefactIds = artefactIdsList.Count > 0 ? JsonSerializer.Serialize(artefactIdsList) : null;
        boardForArtefactUpdate.SavedArtefactIds = savedInstanceIds.Count > 0 ? JsonSerializer.Serialize(savedInstanceIds) : null;
        _context.SavedBoards.Update(boardForArtefactUpdate);
      }
    }
    else
    {
      savedArtefact.PosX = request.PosX;
      savedArtefact.PosY = request.PosY;
      savedArtefact.Width = request.Width;
      savedArtefact.Height = request.Height;
    }

    var board = await _context.SavedBoards.FindAsync(boardId);
    if (board != null)
    {
      board.ModifiedDate = DateTime.UtcNow;
    }

    try
    {
      await _context.SaveChangesAsync();
      return Ok(new { message = "Artefact layout updated successfully" });
    }
    catch (Exception ex)
    {
      Console.WriteLine($"Error updating artefact layout: {ex.Message}");
      return StatusCode(500, "Error updating artefact layout");
    }
  }

  // DELETE: api/Boards/{boardId}/artefacts/{savedArtefactId}
  /// <summary>
  /// Remove a specific artefact from a board
  /// </summary>
  [HttpDelete("{boardId}/artefacts/{savedArtefactId}")]
  public async Task<IActionResult> RemoveArtefactFromBoard(string boardId, string savedArtefactId)
  {
    var userId = User.FindFirst("id")?.Value;
    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized("Invalid token");
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardId && b.UserId == userId)
        .Include(b => b.SavedArtefacts)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound("Board not found");
    }

    var savedArtefactToRemove = board.SavedArtefacts
        .FirstOrDefault(sa => sa.Id == savedArtefactId);

    if (savedArtefactToRemove == null)
    {
      return NotFound("Saved artefact not found on this board");
    }

    try
    {
      _context.SavedArtefacts.Remove(savedArtefactToRemove);

      var remainingSavedArtefacts = board.SavedArtefacts
          .Where(sa => sa.Id != savedArtefactId)
          .ToList();

      var artefactIds = remainingSavedArtefacts.Select(sa => sa.ArtefactId).ToList();
      var savedArtefactIds = remainingSavedArtefacts.Select(sa => sa.Id).ToList();

      board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
      board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
      board.ModifiedDate = DateTime.UtcNow;

      _context.SavedBoards.Update(board);
      await _context.SaveChangesAsync();

      return NoContent();
    }
    catch (Exception ex)
    {
      Console.WriteLine($"Error removing artefact from board: {ex.Message}");
      return StatusCode(500, "Error removing artefact from board");
    }
  }

  // DELETE: api/Boards/{boardId}/artefacts
  /// <summary>
  /// Clear all artefacts from a board (without deleting the board itself)
  /// </summary>
  [HttpDelete("{boardId}/artefacts")]
  public async Task<IActionResult> ClearBoard(string boardId)
  {
    var userId = User.FindFirst("id")?.Value;
    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized("Invalid token");
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardId && b.UserId == userId)
        .Include(b => b.SavedArtefacts)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound("Board not found");
    }

    try
    {
      if (board.SavedArtefacts != null && board.SavedArtefacts.Any())
      {
        _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
      }

      board.ArtefactIds = null;
      board.SavedArtefactIds = null;
      board.ModifiedDate = DateTime.UtcNow;

      _context.SavedBoards.Update(board);
      await _context.SaveChangesAsync();

      return Ok(new { message = "Board cleared successfully" });
    }
    catch (Exception ex)
    {
      Console.WriteLine($"Error clearing board: {ex.Message}");
      return StatusCode(500, "Error clearing board");
    }
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
    var userId = User.FindFirst("id")?.Value;

    if (string.IsNullOrEmpty(userId))
    {
      return Unauthorized();
    }

    var board = await _context.SavedBoards
        .Where(b => b.Id == boardId && b.UserId == userId)
        .Include(b => b.SavedArtefacts)
        .FirstOrDefaultAsync();

    if (board == null)
    {
      return NotFound();
    }

    _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);

    _context.SavedBoards.Remove(board);

    await _context.SaveChangesAsync();

    return NoContent();
  }

  private bool BoardExists(string id)
  {
    return _context.SavedBoards.Any(e => e.Id == id);
  }
}