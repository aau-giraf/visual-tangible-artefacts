using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
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
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Return the created board
                    return new BoardLayoutResponseDTO
                    {
                        BoardId = board.Id,
                        Name = board.Name,
                        CreatedDate = board.CreatedDate,
                        ModifiedDate = board.ModifiedDate,
                        Artefacts = request.Artefacts
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

                    // Remove existing artefact layouts
                    _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);

                    // Add updated artefact layouts
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
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Return the updated board
                    return new BoardLayoutResponseDTO
                    {
                        BoardId = board.Id,
                        Name = board.Name,
                        CreatedDate = board.CreatedDate,
                        ModifiedDate = board.ModifiedDate,
                        Artefacts = request.Artefacts
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

        // Find the saved artefact entry
        var savedArtefact = await _context.SavedArtefacts
            .FirstOrDefaultAsync(sa => sa.BoardId == boardId && sa.ArtefactId == request.ArtefactId);

        if (savedArtefact == null)
        {
            // Create new entry if it doesn't exist
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
        }
        else
        {
            // Update existing entry
            savedArtefact.PosX = request.PosX;
            savedArtefact.PosY = request.PosY;
            savedArtefact.Width = request.Width;
            savedArtefact.Height = request.Height;
        }

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
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found");
        }

        try
        {
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
