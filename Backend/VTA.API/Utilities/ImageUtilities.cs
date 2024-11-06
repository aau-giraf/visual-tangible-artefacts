namespace VTA.API.Utilities;

public static class ImageUtilities
{
    private static string _APIEndpoint = "/api/Assets/";
    private static string _Dir = "";

    public static string? AddImage(IFormFile? image, string artefactId, string dir)
    {
        _Dir = dir;
        _APIEndpoint = _APIEndpoint + _Dir+"/";
        if (image != null && image.Length > 0)
        {
            string fileName = artefactId + Path.GetExtension(image.FileName);
            string imageFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir);
            string filePath = Path.Combine(imageFolder, fileName);

            using (FileStream stream = new FileStream(filePath, FileMode.Create))
            {
                image.CopyTo(stream);
            }
            return $"{_APIEndpoint}{fileName}";
        }
        return null;
    }
    public static bool? DeleteImage(string imgName, string dir)
    {
        _Dir = dir;
        string? file = FindFile(imgName);

        if (file == null) { return null; }

        string path = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir, file);
        File.Delete(path);

        return true;
    }

    private static string? FindFile(string fileName)
    {
        string? file = "";
        try
        {
            string path = Path.Combine(Directory.GetCurrentDirectory(), "Assets", _Dir);
            var tempfile = Directory.EnumerateFiles(path)
                        .FirstOrDefault(f => Path.GetFileNameWithoutExtension(f).Equals(fileName, StringComparison.OrdinalIgnoreCase));

            file = tempfile?.Replace(path, "").Remove(0, 1);
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex);
        }

        // Return the file if found, or null if no match
        return file != null ? file : null;
    }
}