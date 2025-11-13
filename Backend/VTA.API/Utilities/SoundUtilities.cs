namespace VTA.API.Utilities;

public static class SoundUtilities
{
    private static string _Dir = "Sounds";

    public static string? AddSound(IFormFile? soundFile, string soundId, string userId)
    {
        

        if (soundFile == null || soundFile.Length == 0)
        {
            
            return null;
        }

        // Add "sound_" prefix to filename for clarity
        string fileName = "sound_" + soundId + Path.GetExtension(soundFile.FileName);
        // Create user-specific folder structure: Assets/Sounds/{userId}/
        string soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir, userId);
        if (!Directory.Exists(soundFolder)) Directory.CreateDirectory(soundFolder);
        string filePath = Path.Combine(soundFolder, fileName);

        

        using (FileStream stream = new FileStream(filePath, FileMode.Create))
        {
            soundFile.CopyTo(stream);
        }

        
        return $"/api/Assets/Sounds/{userId}/{fileName}";
    }

    public static string? AddSound(byte[]? soundData, string soundId, string userId, string fileExtension = ".mp3")
    {
        if (soundData == null || soundData.Length == 0)
        {
            return null;
        }

        // Add "sound_" prefix to filename for clarity
        string fileName = "sound_" + soundId + fileExtension;
        // Create user-specific folder structure: Assets/Sounds/{userId}/
        string soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir, userId);
        if (!Directory.Exists(soundFolder)) Directory.CreateDirectory(soundFolder);
        string filePath = Path.Combine(soundFolder, fileName);

        File.WriteAllBytes(filePath, soundData);

        return $"/api/Assets/Sounds/{userId}/{fileName}";
    }

    public static bool? DeleteSound(string soundId, string userId)
    {
        // Search in user-specific directory: Assets/Sounds/{userId}/
        string path = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir, userId);

        // Ensure user directory exists before searching
        if (!Directory.Exists(path))
        {
            return null;
        }

        // Look for files with "sound_" prefix
        var file = Directory.EnumerateFiles(path)
                    .FirstOrDefault(f => Path.GetFileNameWithoutExtension(f).Equals("sound_" + soundId, StringComparison.OrdinalIgnoreCase));
        if (file == null) return null;
        File.Delete(file);
        return true;
    }
}
