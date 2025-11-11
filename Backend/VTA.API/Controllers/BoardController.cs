using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using System.Text.Json;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing saved board layouts and artefact positions
/// </summary>
[Authorize]
[Route("api/Users/Boards")]
[ApiController]
public class BoardController : ControllerBase
{
    private readonly VTAContext _context;

    public BoardController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all saved boards for the current user
    /// </summary>
    /// <returns>List of saved boards</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<BoardLayoutResponseDTO>>> GetBoards()
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

            var boards = await _context.SavedBoards
            .Where(b => b.UserId == userId)
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .Select(b => new BoardLayoutResponseDTO
            {
                BoardId = b.Id,
                Name = b.Name,
                CreatedDate = b.CreatedDate,
                ModifiedDate = b.ModifiedDate,
                    Artefacts = b.SavedArtefacts.Select(sa => new BoardArtefactLayoutDTO
                    {
                        SavedArtefactId = sa.Id,
                        ArtefactId = sa.ArtefactId,
                        PosX = sa.PosX,
                        PosY = sa.PosY,
                        Width = sa.Width,
                        Height = sa.Height
                    }).ToList()
            })
            .ToListAsync();

        return Ok(boards);
    }

    /// <summary>
    /// Get a specific board layout by ID
    /// </summary>
    /// <param name="boardId">The ID of the board to retrieve</param>
    /// <returns>Board layout with artefact positions</returns>
    [HttpGet("{boardId}")]
    public async Task<ActionResult<BoardLayoutResponseDTO>> GetBoard(string boardId)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found");
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

    /// <summary>
    /// Save a new board layout
    /// </summary>
    /// <param name="request">Board data with artefact positions and sizes</param>
    /// <returns>Created board information</returns>
    [HttpPost]
    public async Task<ActionResult<BoardLayoutResponseDTO>> SaveBoard([FromBody] SaveBoardRequestDTO request)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest("Board name is required");
        }

        try
        {
            // Use execution strategy to handle the transaction properly
            var strategy = _context.Database.CreateExecutionStrategy();
            var response = await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    // Create the board
                    var board = new SavedBoard
                    {
                        Id = Guid.NewGuid().ToString(),
                        Name = request.Name,
                        UserId = userId,
                        CreatedDate = DateTime.UtcNow
                    };

                    _context.SavedBoards.Add(board);
                    await _context.SaveChangesAsync();

                    // Add artefacts to the board
                    var artefactIds = new List<string>();
                    var savedArtefactIds = new List<string>();
                    
                    foreach (var artefactLayout in request.Artefacts)
                    {
                        // Verify the artefact exists and belongs to the user
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

                        // Track both artefactId and savedArtefactId for the board-level JSON arrays
                        artefactIds.Add(artefactLayout.ArtefactId);
                        savedArtefactIds.Add(savedArtefact.Id);
                    }

                    // Serialize lists into JSON for quick lookup
                    board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
                    board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;

                    // Persist everything
                    _context.SavedBoards.Update(board);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Reload the saved artefacts so we return the instance ids
                    var createdBoard = await _context.SavedBoards
                        .Where(b => b.Id == board.Id)
                        .Include(b => b.SavedArtefacts)
                        .FirstOrDefaultAsync();

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

            return CreatedAtAction(nameof(GetBoard), new { boardId = response.BoardId }, response);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving board: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            
            // Check if it's a database column issue
            if (ex.Message.Contains("Unknown column") || ex.Message.Contains("width") || ex.Message.Contains("height"))
            {
                return StatusCode(500, "Database schema needs migration. Please run the migration endpoint first.");
            }
            
            return StatusCode(500, "Error saving board");
        }
    }

    /// <summary>
    /// Update an existing board layout
    /// </summary>
    /// <param name="boardId">The ID of the board to update</param>
    /// <param name="request">Updated board data</param>
    /// <returns>Updated board information</returns>
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
            // Use execution strategy to handle the transaction properly
            var strategy = _context.Database.CreateExecutionStrategy();
            var response = await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    // Update board properties
                    board.Name = request.Name;
                    board.ModifiedDate = DateTime.UtcNow;

                    // Smart cleanup: only remove/add what has actually changed
                    var existingSavedArtefacts = board.SavedArtefacts.ToList();
                    var newArtefactLayouts = request.Artefacts.ToList();

                    // Find saved artefacts to remove (those not in the new layout)
                    var artefactsToRemove = existingSavedArtefacts.Where(existing =>
                        !newArtefactLayouts.Any(newLayout => 
                            newLayout.ArtefactId == existing.ArtefactId &&
                            Math.Abs(newLayout.PosX - existing.PosX) < 0.001f &&
                            Math.Abs(newLayout.PosY - existing.PosY) < 0.001f &&
                            Math.Abs(newLayout.Width - existing.Width) < 0.001f &&
                            Math.Abs(newLayout.Height - existing.Height) < 0.001f
                        )
                    ).ToList();

                    // Remove outdated saved artefacts
                    if (artefactsToRemove.Any())
                    {
                        _context.SavedArtefacts.RemoveRange(artefactsToRemove);
                    }

                    // Prepare lists for JSON serialization
                    var artefactIds = new List<string>();
                    var savedArtefactIds = new List<string>();

                    // Keep existing saved artefacts that haven't changed
                    var keptSavedArtefacts = existingSavedArtefacts.Except(artefactsToRemove).ToList();
                    foreach (var keptArtefact in keptSavedArtefacts)
                    {
                        artefactIds.Add(keptArtefact.ArtefactId);
                        savedArtefactIds.Add(keptArtefact.Id);
                    }
                    
                    // Add only new artefact layouts (those not already on the board)
                    foreach (var artefactLayout in newArtefactLayouts)
                    {
                        // Check if this exact artefact layout already exists
                        var alreadyExists = keptSavedArtefacts.Any(existing =>
                            existing.ArtefactId == artefactLayout.ArtefactId &&
                            Math.Abs(artefactLayout.PosX - existing.PosX) < 0.001f &&
                            Math.Abs(artefactLayout.PosY - existing.PosY) < 0.001f &&
                            Math.Abs(artefactLayout.Width - existing.Width) < 0.001f &&
                            Math.Abs(artefactLayout.Height - existing.Height) < 0.001f
                        );

                        if (alreadyExists)
                        {
                            // This artefact layout already exists, skip creating it
                            continue;
                        }

                        // Verify the artefact exists and belongs to the user
                        var artefactExists = await _context.Artefacts
                            .AnyAsync(a => a.ArtefactId == artefactLayout.ArtefactId && a.UserId == userId);

                        if (!artefactExists)
                        {
                            throw new InvalidOperationException($"Artefact {artefactLayout.ArtefactId} not found or doesn't belong to user");
                        }

                        // Create new saved artefact
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

                        // Track the new artefact in the JSON arrays
                        artefactIds.Add(artefactLayout.ArtefactId);
                        savedArtefactIds.Add(savedArtefact.Id);
                    }

                    // Serialize lists into JSON for quick lookup
                    board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
                    board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
                    _context.SavedBoards.Update(board);

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Reload updated saved artefacts to include instance ids
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
            
            // Check if it's a database column issue
            if (ex.Message.Contains("Unknown column") || ex.Message.Contains("width") || ex.Message.Contains("height"))
            {
                return StatusCode(500, "Database schema needs migration. Please run the migration endpoint first.");
            }
            
            return StatusCode(500, "Error updating board");
        }
    }

    /// <summary>
    /// Update the position and size of a specific artefact on a board
    /// </summary>
    /// <param name="boardId">The ID of the board</param>
    /// <param name="request">Updated artefact layout data</param>
    /// <returns>Success message</returns>
    [HttpPatch("{boardId}/artefacts")]
    public async Task<IActionResult> UpdateArtefactLayout(string boardId, [FromBody] UpdateArtefactLayoutDTO request)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        // Verify the board exists and belongs to the user
        var boardExists = await _context.SavedBoards
            .AnyAsync(b => b.Id == boardId && b.UserId == userId);

        if (!boardExists)
        {
            return NotFound("Board not found");
        }

        // Find the saved artefact entry when an explicit SavedArtefactId is provided.
        // IMPORTANT: do NOT fallback to matching by ArtefactId — when SavedArtefactId is missing we should create a new instance
        // (PATCH must target a specific instance). This prevents accidental updates of the wrong instance when duplicates exist.
        SavedArtefact? savedArtefact = null;

        if (!string.IsNullOrEmpty(request.SavedArtefactId))
        {
            savedArtefact = await _context.SavedArtefacts
                .FirstOrDefaultAsync(sa => sa.Id == request.SavedArtefactId && sa.BoardId == boardId);
        }

        if (savedArtefact == null)
        {
            // Do NOT create a new saved artefact via PATCH. The client must create new instances via PUT (UpdateBoard)
            // or POST (SaveBoard). Returning BadRequest prevents PATCH from silently creating duplicates when the client
            // accidentally omits the SavedArtefactId for duplicates.
            return BadRequest("SavedArtefactId is required to update an existing saved artefact. Create a new saved artefact via updating the board.");
        }

        // Update existing entry
        savedArtefact.PosX = request.PosX;
        savedArtefact.PosY = request.PosY;
        savedArtefact.Width = request.Width;
        savedArtefact.Height = request.Height;

        // Update board modified date
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

    /// <summary>
    /// Remove a specific artefact from a board
    /// </summary>
    /// <param name="boardId">The ID of the board</param>
    /// <param name="savedArtefactId">The ID of the saved artefact to remove</param>
    /// <returns>Success message</returns>
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
            // Remove the specific saved artefact
            _context.SavedArtefacts.Remove(savedArtefactToRemove);
            
            // Update the board's JSON arrays
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
            
            return Ok(new { message = "Artefact removed from board successfully" });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error removing artefact from board: {ex.Message}");
            return StatusCode(500, "Error removing artefact from board");
        }
    }

    /// <summary>
    /// Clear all artefacts from a board (without deleting the board itself)
    /// </summary>
    /// <param name="boardId">The ID of the board to clear</param>
    /// <returns>Success message</returns>
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
            // Remove all saved artefacts from the board
            if (board.SavedArtefacts != null && board.SavedArtefacts.Any())
            {
                _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
            }
            
            // Clear the JSON arrays
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

    /// <summary>
    /// Delete a saved board
    /// </summary>
    /// <param name="boardId">The ID of the board to delete</param>
    /// <returns>Success message</returns>
    [HttpDelete("{boardId}")]
    public async Task<IActionResult> DeleteBoard(string boardId)
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
            // First remove all associated saved artefacts
            if (board.SavedArtefacts != null && board.SavedArtefacts.Any())
            {
                _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
            }
            
            // Then remove the board itself
            _context.SavedBoards.Remove(board);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Board deleted successfully" });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error deleting board: {ex.Message}");
            return StatusCode(500, "Error deleting board");
        }
    }
}
