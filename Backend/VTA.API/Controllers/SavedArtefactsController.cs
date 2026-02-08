using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VTA.API.DTOs;
using VTA.API.Services;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing saved artefacts on boards.
/// Provides endpoints to update artefact layout, remove artefacts from boards, and clear all artefacts from a board.
/// Delegates to <see cref="IBoardService"/> for all business logic.
/// </summary>
[Authorize]
[Route("api/Boards/{boardId}/SavedArtefacts")]
[ApiController]
public class SavedArtefactsController : ControllerBase
{
  private readonly IBoardService _boardService;

  /// <summary>
  /// Initializes a new instance of the <see cref="SavedArtefactsController"/> class.
  /// </summary>
  /// <param name="boardService">The <see cref="IBoardService"/> used to manage boards and artefacts.</param>
  public SavedArtefactsController(IBoardService boardService)
  {
    _boardService = boardService;
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
    if (string.IsNullOrEmpty(userId)) return Unauthorized("Invalid token");

    var (success, error) = await _boardService.UpdateSavedArtefactLayoutAsync(boardId, userId, request);

    return error switch
    {
      "NotFound" => NotFound("Board or saved artefact not found"),
      "BadRequest" => BadRequest("SavedArtefactId is required to update an existing saved artefact. Create a new saved artefact via updating the board."),
      _ when success => Ok(new { message = "Artefact layout updated successfully" }),
      _ => StatusCode(500, "Error updating artefact layout")
    };
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
    if (string.IsNullOrEmpty(userId)) return Unauthorized("Invalid token");

    var (success, error) = await _boardService.RemoveArtefactFromBoardAsync(boardId, savedArtefactId, userId);

    if (!success)
    {
      return NotFound(error == "NotFound" ? "Board or saved artefact not found" : "Error removing artefact");
    }

    return Ok(new { message = "Artefact removed from board successfully" });
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
    if (string.IsNullOrEmpty(userId)) return Unauthorized("Invalid token");

    // This endpoint also deletes Session-Artefacts (unlike BoardsController.ClearBoard)
    var (success, _) = await _boardService.ClearBoardAsync(boardId, userId, deleteSessionArtefacts: true);

    if (!success) return NotFound("Board not found");

    return Ok(new { message = "Board cleared successfully" });
  }
}