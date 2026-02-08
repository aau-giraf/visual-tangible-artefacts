using VTA.API.DTOs;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Service for board CRUD, artefact layout management, and board clearing/deletion.
/// Unifies logic previously duplicated across BoardsController and SavedArtefactsController.
/// </summary>
public interface IBoardService
{
    /// <summary>
    /// Get all boards owned by the specified user, ordered by most-recently-modified.
    /// Includes SavedArtefact navigation data.
    /// </summary>
    Task<List<SavedBoard>> GetBoardsForUserAsync(string userId);

    /// <summary>
    /// Get a lightweight list of boards (no artefact navigation) for listing UI.
    /// </summary>
    Task<List<SavedBoard>> GetBoardListAsync(string userId);

    /// <summary>
    /// Get a single board with all its saved artefacts (including nested Artefact entities).
    /// </summary>
    Task<SavedBoard?> GetBoardAsync(string boardId, string userId);

    /// <summary>
    /// Create a new board with optional artefact layouts.
    /// When <paramref name="artefacts"/> is non-empty, the artefacts are validated
    /// against the user, placed on the board, and the board's JSON ID-lists are set.
    /// </summary>
    /// <returns>The created board with SavedArtefacts populated.</returns>
    Task<SavedBoard> CreateBoardAsync(string userId, string name, List<BoardArtefactLayoutDTO>? artefacts = null);

    /// <summary>
    /// Replace a board's artefact layout entirely (PUT semantics).
    /// Existing saved artefacts are kept, new ones from the request are appended,
    /// and the board's JSON ID-lists are rebuilt.
    /// </summary>
    /// <returns>The updated board, or null if not found.</returns>
    Task<SavedBoard?> UpdateBoardAsync(string boardId, string userId, string name, List<BoardArtefactLayoutDTO> artefacts);

    /// <summary>
    /// Patch individual fields on a board (name, snapshotPath).
    /// </summary>
    /// <returns>True on success, false if the board was not found.</returns>
    Task<bool> PatchBoardAsync(string boardId, string userId, string? name, string? snapshotPath);

    /// <summary>
    /// Upsert the layout of a single artefact on a board.
    /// Creates a new <see cref="SavedArtefact"/> when no existing entry matches.
    /// </summary>
    /// <returns>True on success, null string. On failure returns false and an error key.</returns>
    Task<(bool Success, string? Error)> UpdateArtefactLayoutAsync(
        string boardId, string userId, UpdateArtefactLayoutDTO request);

    /// <summary>
    /// Update layout of a specific saved artefact by its SavedArtefactId (strict PATCH, no upsert).
    /// </summary>
    /// <returns>
    /// <c>(true, null)</c> on success,
    /// <c>(false, "NotFound")</c> if board or saved artefact not found,
    /// <c>(false, "BadRequest")</c> if SavedArtefactId is missing.
    /// </returns>
    Task<(bool Success, string? Error)> UpdateSavedArtefactLayoutAsync(
        string boardId, string userId, UpdateArtefactLayoutDTO request);

    /// <summary>
    /// Remove a specific saved artefact from a board and update JSON ID-lists.
    /// </summary>
    Task<(bool Success, string? Error)> RemoveArtefactFromBoardAsync(
        string boardId, string savedArtefactId, string userId);

    /// <summary>
    /// Clear all saved artefacts from a board (does not delete the board itself).
    /// Optionally also deletes Session-Artefact category artefacts referenced by the board.
    /// </summary>
    /// <param name="boardId">Board to clear.</param>
    /// <param name="userId">Owner's user ID.</param>
    /// <param name="deleteSessionArtefacts">
    /// When true, artefacts with <c>CategoryId == "Session-Artefact"</c> referenced
    /// by this board are also deleted from the Artefacts table.
    /// </param>
    Task<(bool Success, string? Error)> ClearBoardAsync(
        string boardId, string userId, bool deleteSessionArtefacts = false);

    /// <summary>
    /// Delete a board and all its saved artefacts.
    /// </summary>
    Task<(bool Success, string? Error)> DeleteBoardAsync(string boardId, string userId);
}
