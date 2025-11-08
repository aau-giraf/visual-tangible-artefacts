using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Users/Boards/{boardId}/Artefacts")]
[ApiController]
public class SavedArtefactsController : ControllerBase
{
    private readonly VTAContext _context;

    public SavedArtefactsController(VTAContext context)
    {
        _context = context;
    }

    // GET: api/Users/Boards/{boardId}/Artefacts
    /// <summary>
    /// Gets all artefacts placed on a specific board
    /// </summary>
    /// <param name="boardId">The board ID</param>
    /// <returns>A collection of saved artefacts on the board</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<SavedArtefactGetDTO>>> GetSavedArtefacts(string boardId)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Verify user owns the board
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found or you don't have permission to access it");
        }

        var savedArtefacts = await _context.SavedArtefacts
            .Where(sa => sa.BoardId == boardId)
            .Include(sa => sa.Artefact)
            .ToListAsync();

        var savedArtefactDTOs = new List<SavedArtefactGetDTO>();
        foreach (var savedArtefact in savedArtefacts)
        {
            savedArtefactDTOs.Add(DTOConverter.MapSavedArtefactToSavedArtefactGetDTO(savedArtefact, Request.Scheme, Request.Host.ToString()));
        }

        return Ok(savedArtefactDTOs);
    }

    // GET: api/Users/Boards/{boardId}/Artefacts/{savedArtefactId}
    /// <summary>
    /// Gets a specific saved artefact
    /// </summary>
    /// <param name="boardId">The board ID</param>
    /// <param name="savedArtefactId">The saved artefact ID</param>
    /// <returns>The specified saved artefact</returns>
    [HttpGet("{savedArtefactId}")]
    public async Task<ActionResult<SavedArtefactGetDTO>> GetSavedArtefact(string boardId, string savedArtefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Verify user owns the board
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found or you don't have permission to access it");
        }

        var savedArtefact = await _context.SavedArtefacts
            .Where(sa => sa.Id == savedArtefactId && sa.BoardId == boardId)
            .Include(sa => sa.Artefact)
            .FirstOrDefaultAsync();

        if (savedArtefact == null)
        {
            return NotFound();
        }

        var savedArtefactDTO = DTOConverter.MapSavedArtefactToSavedArtefactGetDTO(savedArtefact, Request.Scheme, Request.Host.ToString());

        return Ok(savedArtefactDTO);
    }

    // POST: api/Users/Boards/{boardId}/Artefacts
    /// <summary>
    /// Places an artefact on a board at a specific position
    /// </summary>
    /// <param name="boardId">The board ID</param>
    /// <param name="savedArtefactPostDTO">Artefact placement data</param>
    /// <returns>The created saved artefact</returns>
    [HttpPost]
    public async Task<ActionResult<SavedArtefactGetDTO>> PostSavedArtefact(string boardId, [FromBody] SavedArtefactPostDTO savedArtefactPostDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Verify user owns the board
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found or you don't have permission to access it");
        }

        // Verify the artefact exists and belongs to the user
        var artefact = await _context.Artefacts
            .Where(a => a.ArtefactId == savedArtefactPostDTO.ArtefactId && a.UserId == userId)
            .FirstOrDefaultAsync();

        if (artefact == null)
        {
            return NotFound("Artefact not found or you don't have permission to use it");
        }

        // Check if artefact is already on this board (due to unique constraint)
        var existingSavedArtefact = await _context.SavedArtefacts
            .Where(sa => sa.ArtefactId == savedArtefactPostDTO.ArtefactId && sa.BoardId == boardId)
            .FirstOrDefaultAsync();

        if (existingSavedArtefact != null)
        {
            return Conflict("This artefact is already placed on this board");
        }

        var savedArtefactId = Guid.NewGuid().ToString();
        var savedArtefact = DTOConverter.MapSavedArtefactPostDTOToSavedArtefact(savedArtefactPostDTO, savedArtefactId, boardId);

        _context.SavedArtefacts.Add(savedArtefact);

        // Update board's modified date
        board.ModifiedDate = DateTime.UtcNow;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            // Handle GUID collision or unique constraint violation
            if (SavedArtefactExists(savedArtefact.Id))
            {
                while (SavedArtefactExists(savedArtefact.Id))
                {
                    savedArtefact.Id = Guid.NewGuid().ToString();
                }
                await _context.SaveChangesAsync();
            }
            else
            {
                Console.WriteLine($"Error saving artefact: {ex.Message}");
                throw;
            }
        }

        // Fetch the created saved artefact with relationships
        var createdSavedArtefact = await _context.SavedArtefacts
            .Include(sa => sa.Artefact)
            .FirstOrDefaultAsync(sa => sa.Id == savedArtefact.Id);

        if (createdSavedArtefact == null)
        {
            return NotFound();
        }

        var savedArtefactGetDTO = DTOConverter.MapSavedArtefactToSavedArtefactGetDTO(createdSavedArtefact, Request.Scheme, Request.Host.ToString());

        return CreatedAtAction(nameof(GetSavedArtefact), new { boardId = boardId, savedArtefactId = savedArtefact.Id }, savedArtefactGetDTO);
    }

    // PATCH: api/Users/Boards/{boardId}/Artefacts/{savedArtefactId}
    /// <summary>
    /// Updates a saved artefact's position on the board
    /// </summary>
    /// <param name="boardId">The board ID</param>
    /// <param name="savedArtefactId">The saved artefact ID</param>
    /// <param name="savedArtefactPatchDTO">Position update data</param>
    /// <returns>No content on success</returns>
    [HttpPatch("{savedArtefactId}")]
    public async Task<IActionResult> PatchSavedArtefact(string boardId, string savedArtefactId, [FromBody] SavedArtefactPatchDTO savedArtefactPatchDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Verify user owns the board
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found or you don't have permission to access it");
        }

        // Verify savedArtefactId matches the one in the URL
        if (savedArtefactId != savedArtefactPatchDTO.SavedArtefactId)
        {
            return BadRequest("SavedArtefactId in URL does not match the one in the request body");
        }

        var savedArtefact = await _context.SavedArtefacts
            .Where(sa => sa.Id == savedArtefactId && sa.BoardId == boardId)
            .FirstOrDefaultAsync();

        if (savedArtefact == null)
        {
            return NotFound();
        }

        // Update position if provided
        if (savedArtefactPatchDTO.PosX.HasValue)
        {
            savedArtefact.PosX = savedArtefactPatchDTO.PosX.Value;
        }

        if (savedArtefactPatchDTO.PosY.HasValue)
        {
            savedArtefact.PosY = savedArtefactPatchDTO.PosY.Value;
        }

        // Update board's modified date
        board.ModifiedDate = DateTime.UtcNow;

        _context.Entry(savedArtefact).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!SavedArtefactExists(savedArtefact.Id))
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

    // DELETE: api/Users/Boards/{boardId}/Artefacts/{savedArtefactId}
    /// <summary>
    /// Removes an artefact from a board
    /// </summary>
    /// <param name="boardId">The board ID</param>
    /// <param name="savedArtefactId">The saved artefact ID</param>
    /// <returns>No content on success</returns>
    [HttpDelete("{savedArtefactId}")]
    public async Task<IActionResult> DeleteSavedArtefact(string boardId, string savedArtefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Verify user owns the board
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null)
        {
            return NotFound("Board not found or you don't have permission to access it");
        }

        var savedArtefact = await _context.SavedArtefacts
            .Where(sa => sa.Id == savedArtefactId && sa.BoardId == boardId)
            .FirstOrDefaultAsync();

        if (savedArtefact == null)
        {
            return NotFound();
        }

        _context.SavedArtefacts.Remove(savedArtefact);

        // Update board's modified date
        board.ModifiedDate = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool SavedArtefactExists(string id)
    {
        return _context.SavedArtefacts.Any(e => e.Id == id);
    }
}