using VTA.API.Utilities;

namespace VTA.API.Services;

/// <summary>
/// Default implementation of <see cref="ISoundService"/>.
/// Delegates to the static <see cref="SoundUtilities"/> methods.
/// Registered as scoped in DI so consumers can be tested with a mock.
/// </summary>
public class SoundService : ISoundService
{
    /// <inheritdoc />
    public Task<string?> AddSoundAsync(IFormFile? soundFile, string soundId, string userId)
    {
        return SoundUtilities.AddSound(soundFile, soundId, userId);
    }

    /// <inheritdoc />
    public Task<string?> AddSoundAsync(byte[]? soundData, string soundId, string userId, string fileExtension = ".mp3")
    {
        return SoundUtilities.AddSound(soundData, soundId, userId, fileExtension);
    }

    /// <inheritdoc />
    public bool? DeleteSound(string soundId, string userId)
    {
        return SoundUtilities.DeleteSound(soundId, userId);
    }
}
