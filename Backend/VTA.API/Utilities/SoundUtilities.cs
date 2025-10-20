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
}
