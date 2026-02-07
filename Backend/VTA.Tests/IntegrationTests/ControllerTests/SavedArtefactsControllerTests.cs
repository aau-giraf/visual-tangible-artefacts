using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.Tests.IntegrationTests.ControllerTests;

/// <summary>
/// Controller for managing saved artefacts on boards.
/// Provides endpoints to update artefact layout, remove artefacts from boards, and clear all artefacts from a board.
/// </summary>
[Authorize]
[Route("api/Boards/{boardId}/SavedArtefacts")]
[ApiController]
public class SavedArtefactsController : ControllerBase
{
  private readonly VTAContext _context;

  /// <summary>
  /// Initializes a new instance of the <see cref="SavedArtefactsController"/> class.
  /// </summary>
  /// <param name="context">The <see cref="VTAContext"/> used to access saved boards and artefacts.</param>
  public SavedArtefactsController(VTAContext context)
  {
    _context = context;
  }

  // PATCH: api/Boards/{boardId}/SavedArtefacts
  /// <summary>
  /// Updates the position and size of a specific artefact on a board
  /// </summary>
  /// <param name="boardId">The ID of the board</param>
  /// <param name="request">Updated artefact layout data</param>
  /// <returns>Success message</returns>
  [HttpPatch]
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

    // Check if values are actually different before updating
    bool hasChanges = savedArtefact.PosX != request.PosX ||
                     savedArtefact.PosY != request.PosY ||
                     savedArtefact.Width != request.Width ||
                     savedArtefact.Height != request.Height;

    if (hasChanges)
    {
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
    }

    try
    {
      await _context.SaveChangesAsync();
      return Ok(new { message = hasChanges ? "Artefact layout updated successfully" : "No changes detected, layout already up to date" });
    }
    catch (Exception)
    {
      return StatusCode(500, "Error updating artefact layout");
    }
  }

  // DELETE: api/Boards/{boardId}/SavedArtefacts/{savedArtefactId}
  /// <summary>
  /// Removes a specific artefact from a board
  /// </summary>
  /// <param name="boardId">The ID of the board</param>
  /// <param name="savedArtefactId">The ID of the saved artefact to remove</param>
  /// <returns>Success message</returns>
  [HttpDelete("{savedArtefactId}")]
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
      
      // Update board modified date
      board.ModifiedDate = DateTime.UtcNow;
      _context.SavedBoards.Update(board);
      
      await _context.SaveChangesAsync();
      
      return Ok(new { message = "Artefact removed from board successfully" });
    }
    catch (Exception)
    {
      return StatusCode(500, "Error removing artefact from board");
    }
  }

  // DELETE: api/Boards/{boardId}/SavedArtefacts
  /// <summary>
  /// Clears all artefacts from a board (without deleting the board itself)
  /// </summary>
  /// <param name="boardId">The ID of the board to clear</param>
  /// <returns>Success message</returns>
  [HttpDelete]
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
      // Collect artefact ids referenced by this board before removing saved instances
      var artefactIdsOnBoard = board.SavedArtefacts?.Select(sa => sa.ArtefactId).Where(id => !string.IsNullOrEmpty(id)).ToList() ?? new List<string>();

      // Remove all saved artefacts from the board
      if (board.SavedArtefacts != null && board.SavedArtefacts.Any())
      {
        _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
      }

      // Also delete any session artefacts (category == 'Session-Artefact') that belong to this user
      if (artefactIdsOnBoard.Any())
      {
        var sessionArtefacts = await _context.Artefacts
            .Where(a => artefactIdsOnBoard.Contains(a.ArtefactId) && a.UserId == userId && a.CategoryId == "Session-Artefact")
            .ToListAsync();

        if (sessionArtefacts != null && sessionArtefacts.Any())
        {
          _context.Artefacts.RemoveRange(sessionArtefacts);
        }
      }

      // Update board modified date
      board.ModifiedDate = DateTime.UtcNow;
      _context.SavedBoards.Update(board);

      await _context.SaveChangesAsync();

      return Ok(new { message = "Board cleared successfully" });
    }
    catch (Exception)
    {
      return StatusCode(500, "Error clearing board");
    }
  }
}