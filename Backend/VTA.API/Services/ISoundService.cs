namespace VTA.API.Services;

/// <summary>
/// Service for managing sound files on the filesystem.
/// Wraps <see cref="Utilities.SoundUtilities"/> static methods as an injectable service,
/// making the file-I/O layer mockable in tests.
/// </summary>
public interface ISoundService
{
    /// <summary>
    /// Save an uploaded sound file and return its relative API path.
    /// </summary>
    /// <param name="soundFile">The uploaded sound file.</param>
    /// <param name="soundId">The sound/artefact ID (used as filename).</param>
    /// <param name="userId">The owner's user ID for user-scoped folders.</param>
    /// <returns>The relative API path, or null if <paramref name="soundFile"/> is null/empty.</returns>
    Task<string?> AddSoundAsync(IFormFile? soundFile, string soundId, string userId);

    /// <summary>
    /// Save raw sound bytes and return the relative API path.
    /// Used by TTS generation (which produces byte[] rather than IFormFile).
    /// </summary>
    /// <param name="soundData">Raw audio bytes.</param>
    /// <param name="soundId">The sound/artefact ID.</param>
    /// <param name="userId">The owner's user ID.</param>
    /// <param name="fileExtension">File extension (default ".mp3").</param>
    /// <returns>The relative API path, or null if <paramref name="soundData"/> is null/empty.</returns>
    Task<string?> AddSoundAsync(byte[]? soundData, string soundId, string userId, string fileExtension = ".mp3");

    /// <summary>
    /// Delete a sound file from the filesystem.
    /// </summary>
    /// <param name="soundId">The sound/artefact ID.</param>
    /// <param name="userId">The owner's user ID.</param>
    /// <returns>True on success, null if the file was not found.</returns>
    bool? DeleteSound(string soundId, string userId);
}
