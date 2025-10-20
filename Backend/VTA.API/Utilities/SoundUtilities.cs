namespace VTA.API.Utilities;

public static class SoundUtilities
{
    private static string _Dir = "Sounds";

    public static string? AddSound(IFormFile? soundFile, string soundId)
    {
        Console.WriteLine($"Debug: SoundUtilities.AddSound called with soundFile: {soundFile != null}, soundId: {soundId}");
        
        if (soundFile == null || soundFile.Length == 0)
        {
            Console.WriteLine($"Debug: SoundUtilities.AddSound - No sound file provided");
            return null;
        }

        string fileName = soundId + Path.GetExtension(soundFile.FileName);
        string soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir);
        if (!Directory.Exists(soundFolder)) Directory.CreateDirectory(soundFolder);
        string filePath = Path.Combine(soundFolder, fileName);

        Console.WriteLine($"Debug: SoundUtilities.AddSound - Saving to: {filePath}");

        using (FileStream stream = new FileStream(filePath, FileMode.Create))
        {
            soundFile.CopyTo(stream);
        }

        Console.WriteLine($"Debug: SoundUtilities.AddSound - File saved successfully, size: {new FileInfo(filePath).Length} bytes");
        return $"/api/Assets/Sounds/{fileName}";
    }

    public static string? AddSound(byte[]? soundData, string soundId, string fileExtension = ".mp3")
    {
        if (soundData == null || soundData.Length == 0)
        {
            return null;
        }

        string fileName = soundId + fileExtension;
        string soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir);
        if (!Directory.Exists(soundFolder)) Directory.CreateDirectory(soundFolder);
        string filePath = Path.Combine(soundFolder, fileName);

        File.WriteAllBytes(filePath, soundData);

        return $"/api/Assets/Sounds/{fileName}";
    }

    public static bool? DeleteSound(string soundId)
    {
        string path = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir);
        var file = Directory.EnumerateFiles(path)
                    .FirstOrDefault(f => Path.GetFileNameWithoutExtension(f).Equals(soundId, StringComparison.OrdinalIgnoreCase));
        if (file == null) return null;
        File.Delete(file);
        return true;
    }

    /// <summary>
    /// Replaces an existing sound file with a new one.
    /// Deletes the old sound file (if it exists) and adds the new one.
    /// </summary>
    /// <param name="soundFile">The new sound file to upload</param>
    /// <param name="soundId">The ID to use for the sound file (typically artefact ID)</param>
    /// <returns>The URL path to the new sound file, or null if the operation failed</returns>
    public static string? ReplaceSound(IFormFile? soundFile, string soundId)
    {
        if (soundFile == null || soundFile.Length == 0)
        {
            return null;
        }

        // Delete existing sound file if it exists
        try
        {
            DeleteSound(soundId);
        }
        catch { }

        // Add the new sound file
        return AddSound(soundFile, soundId);
    }

    /// <summary>
    /// Replaces an existing sound file with new audio data.
    /// Deletes the old sound file (if it exists) and adds the new one.
    /// </summary>
    /// <param name="soundData">The new audio data as byte array</param>
    /// <param name="soundId">The ID to use for the sound file (typically artefact ID)</param>
    /// <param name="fileExtension">The file extension (default: .mp3)</param>
    /// <returns>The URL path to the new sound file, or null if the operation failed</returns>
    public static string? ReplaceSound(byte[]? soundData, string soundId, string fileExtension = ".mp3")
    {
        if (soundData == null || soundData.Length == 0)
        {
            return null;
        }

        // Delete existing sound file if it exists
        try
        {
            DeleteSound(soundId);
        }
        catch { }

        // Add the new sound file
        return AddSound(soundData, soundId, fileExtension);
    }
}
