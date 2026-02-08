namespace VTA.API.Services;

/// <summary>
/// Service for managing image files on the filesystem.
/// Wraps <see cref="Utilities.ImageUtilities"/> static methods as an injectable service,
/// making the file-I/O layer mockable in tests.
/// </summary>
public interface IImageService
{
    /// <summary>
    /// Save an uploaded image to the filesystem and return its relative API path.
    /// </summary>
    /// <param name="image">The uploaded image file.</param>
    /// <param name="entityId">The owning entity ID (artefact or category).</param>
    /// <param name="directory">Target subdirectory (e.g. "Artefacts", "Categories").</param>
    /// <param name="userId">The owner's user ID for user-scoped folders.</param>
    /// <returns>The relative API path, or null if <paramref name="image"/> is null/empty.</returns>
    Task<string?> AddImageAsync(IFormFile? image, string entityId, string directory, string userId);

    /// <summary>
    /// Delete an image from the filesystem.
    /// </summary>
    /// <param name="entityId">The owning entity ID.</param>
    /// <param name="directory">Target subdirectory.</param>
    /// <param name="userId">The owner's user ID.</param>
    /// <returns>True on success, null if the file was not found.</returns>
    bool? DeleteImage(string entityId, string directory, string userId);
}
