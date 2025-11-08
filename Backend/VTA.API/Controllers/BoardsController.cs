using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Users/Boards")]
[ApiController]
public class BoardsController : ControllerBase
{
    private readonly VTAContext _context;

    public BoardsController(VTAContext context)
    {
        _context = context;
    }

    // GET: api/Users/Boards
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

        var boardDTOs = new List<BoardGetDTO>();
        foreach (var board in boards)
        {
            boardDTOs.Add(DTOConverter.MapSavedBoardToBoardGetDTO(board, Request.Scheme, Request.Host.ToString()));
        }

        return Ok(boardDTOs);
    }

    // GET: api/Users/Boards/list
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

        var boardListItems = new List<BoardListItemDTO>();
        foreach (var board in boards)
        {
            boardListItems.Add(DTOConverter.MapSavedBoardToBoardListItemDTO(board, Request.Scheme, Request.Host.ToString()));
        }

        return Ok(boardListItems);
    }

    // GET: api/Users/Boards/{boardId}
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

        var boardDTO = DTOConverter.MapSavedBoardToBoardGetDTO(board, Request.Scheme, Request.Host.ToString());

        return Ok(boardDTO);
    }

    // POST: api/Users/Boards
    /// <summary>
    /// Creates a new board for the authenticated user
    /// </summary>
    /// <param name="boardPostDTO">Board creation data</param>
    /// <returns>The created board</returns>
    [HttpPost]
    public async Task<ActionResult<BoardGetDTO>> PostBoard([FromBody] BoardPostDTO boardPostDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var boardId = Guid.NewGuid().ToString();
        var board = DTOConverter.MapBoardPostDTOToSavedBoard(boardPostDTO, boardId, userId);

        _context.SavedBoards.Add(board);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Handle GUID collision (extremely unlikely)
            if (BoardExists(board.Id))
            {
                while (BoardExists(board.Id))
                {
                    board.Id = Guid.NewGuid().ToString();
                }
                await _context.SaveChangesAsync();
            }
            else
            {
                throw;
            }
        }

        // Fetch the created board with relationships
        var createdBoard = await _context.SavedBoards
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .FirstOrDefaultAsync(b => b.Id == board.Id);

        if (createdBoard == null)
        {
            return NotFound();
        }

        var boardGetDTO = DTOConverter.MapSavedBoardToBoardGetDTO(createdBoard, Request.Scheme, Request.Host.ToString());

        return CreatedAtAction(nameof(GetBoard), new { boardId = board.Id }, boardGetDTO);
    }

    // PATCH: api/Users/Boards
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

    // DELETE: api/Users/Boards/{boardId}
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
            .Include(b => b.SavedArtefacts) // Include to cascade delete
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound();
        }

        // Remove all saved artefacts first (if cascade is not set to delete)
        _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);

        // Remove the board
        _context.SavedBoards.Remove(board);

        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool BoardExists(string id)
    {
        return _context.SavedBoards.Any(e => e.Id == id);
    }
}