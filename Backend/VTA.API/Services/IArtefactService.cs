using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Service for artefact CRUD and asset management.
/// Encapsulates business logic previously inline in ArtefactsController:
/// ownership validation, upsert semantics, image/sound file management,
/// and bulk updates.
/// </summary>
public interface IArtefactService
{
    /// <summary>
    /// Get all artefacts owned by the specified user.
    /// When <paramref name="skip"/> and <paramref name="take"/> are provided,
    /// returns a paginated subset.
    /// </summary>
    Task<List<Artefact>> GetArtefactsForUserAsync(string userId, int? skip = null, int? take = null);

    /// <summary>
    /// Get a single artefact by ID, scoped to the specified user.
    /// Returns null when not found or not owned by the user.
    /// </summary>
    Task<Artefact?> GetArtefactByIdAsync(string artefactId, string userId);

    /// <summary>
    /// Create a new artefact or update an existing one (upsert).
    /// Handles GUID generation, image/sound file persistence, and
    /// inheriting the user's default <c>NameVisible</c> setting.
    /// </summary>
    /// <param name="artefactId">Caller-supplied ID, or null to auto-generate.</param>
    /// <param name="userId">Owner's user ID.</param>
    /// <param name="name">Artefact display name.</param>
    /// <param name="artefactIndex">Sort order index.</param>
    /// <param name="categoryId">Optional category ID.</param>
    /// <param name="nameShown">Whether the name label is visible (null = inherit user default).</param>
    /// <param name="image">Image file to persist.</param>
    /// <param name="sound">Optional sound file to persist.</param>
    /// <returns>The created or updated <see cref="Artefact"/> entity.</returns>
    Task<Artefact> CreateOrUpdateArtefactAsync(
        string? artefactId,
        string userId,
        string? name,
        ushort artefactIndex,
        string? categoryId,
        bool? nameShown,
        IFormFile image,
        IFormFile? sound);

    /// <summary>
    /// Patch individual fields on an existing artefact.
    /// Only non-null DTO values are applied.
    /// </summary>
    /// <returns>The updated entity, or null if the artefact was not found.</returns>
    Task<Artefact?> PatchArtefactAsync(
        string artefactId,
        string userId,
        ushort? artefactIndex,
        string? name,
        bool? nameShown,
        IFormFile? image,
        IFormFile? sound);

    /// <summary>
    /// Delete an artefact and its associated image/sound files.
    /// </summary>
    /// <returns>
    /// <c>(true, null)</c> on success,
    /// <c>(false, "NotFound")</c> if the artefact does not exist,
    /// <c>(false, "Forbidden")</c> if the artefact belongs to another user.
    /// </returns>
    Task<(bool Success, string? Error)> DeleteArtefactAsync(string artefactId, string userId);

    /// <summary>
    /// Set <c>NameShown</c> to the given value for every artefact owned by the user.
    /// </summary>
    /// <returns>The number of artefacts that were updated.</returns>
    Task<int> BulkUpdateNameShownAsync(string userId, bool nameShown);

    /// <summary>
    /// Check whether the artefact exists and return its <c>SoundPath</c>.
    /// Used by the <c>play-audio</c> endpoint to resolve the file on disk.
    /// </summary>
    /// <returns>The entity (with SoundPath populated), or null.</returns>
    Task<Artefact?> GetArtefactForAudioAsync(string artefactId, string userId);
}
