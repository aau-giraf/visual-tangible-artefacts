using Microsoft.IdentityModel.Tokens;

namespace VTA.API.Utilities;

public static class ImageUtilities
{
    private static string _APIEndpoint = "/api/Assets/";
    private static string _Dir = "Assets";

    public static string? AddImage(IFormFile? image, string id)
    {
        if (image != null && image.Length > 0)
        {
            string fileName = id + (Path.GetExtension(image.FileName));
            string imageFolder = Path.Combine(Directory.GetCurrentDirectory(), _Dir);
            string filePath = Path.Combine(imageFolder, fileName);

            using (FileStream stream = new FileStream(filePath, FileMode.Create))
            {
                image.CopyTo(stream);
            }
            return $"{_APIEndpoint}{fileName}";
        }
        return null;
    }
    public static bool? DeleteImage(string imgName)
    {
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

    private static string? GetFileType(IFormFile file)
    {
        if (file == null)
        {
            throw new ArgumentNullException(nameof(file));
        }

        // Read the first few bytes of the file to identify the type
        using (var reader = new BinaryReader(file.OpenReadStream()))
        {
            // Read the first 4 bytes of the file
            byte[] fileSignature = reader.ReadBytes(4);

            // Check for common image file signatures
            if (fileSignature.Length >= 4)
            {
                // PNG file signature (89 50 4E 47)
                if (fileSignature[0] == 0x89 && fileSignature[1] == 0x50 &&
                    fileSignature[2] == 0x4E && fileSignature[3] == 0x47)
                {
                    return "png";
                }
                // JPEG file signature (FF D8 FF E0 or FF D8 FF E1)
                else if (fileSignature[0] == 0xFF && fileSignature[1] == 0xD8 &&
                         (fileSignature[2] == 0xFF && (fileSignature[3] == 0xE0 || fileSignature[3] == 0xE1)))
                {
                    return "jpeg";
                }
                // GIF file signature (47 49 46 38)
                else if (fileSignature[0] == 0x47 && fileSignature[1] == 0x49 &&
                         fileSignature[2] == 0x46 && fileSignature[3] == 0x38)
                {
                    return "gif";
                }
                // BMP file signature (42 4D)
                else if (fileSignature[0] == 0x42 && fileSignature[1] == 0x4D)
                {
                    return "bmp";
                }
                // TIFF file signature (49 20 49 or 4D 4D 00 2A)
                else if ((fileSignature[0] == 0x49 && fileSignature[1] == 0x49) ||
                         (fileSignature[0] == 0x4D && fileSignature[1] == 0x4D))
                {
                    return "tiff";
                }
                // PDF file signature (25 50 44 46)
                else if (fileSignature[0] == 0x25 && fileSignature[1] == 0x50 &&
                         fileSignature[2] == 0x44 && fileSignature[3] == 0x46)
                {
                    return "pdf";
                }
            }

            // If signature is not recognized
            return null;
        }
    }
}