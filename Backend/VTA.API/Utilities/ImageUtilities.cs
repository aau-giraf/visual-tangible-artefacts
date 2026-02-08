using Microsoft.IdentityModel.Tokens;

namespace VTA.API.Utilities;

public static class ImageUtilities
{
    // Cache the base assets path to avoid repeated Directory.GetCurrentDirectory() calls
    private static readonly string BaseAssetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets");
    //private static string _APIEndpoint = "";
    private static string _Dir = "";
    /// <summary>
    /// Adds the uploaded image to the file system
    /// </summary>
    /// <param name="image">The uploaded IFormFile</param>
    /// <param name="artefactId">The artefacts ID</param>
    /// <param name="dir">The dir to upload it (Artefact or Category image)</param>
    /// <param name="userId">The user ID for organizing files by user</param>
    /// <returns>null if nothing image is null <br/>The file path for the image that was</returns>
    public static async Task<string?> AddImage(IFormFile? image, string artefactId, string dir, string userId)
    {
        _Dir = dir;
        string _APIEndpoint = "/api/Assets/" + _Dir + "/";
        if (image != null && image.Length > 0)
        {
            // Add "image_" prefix to filename for clarity
            string fileName = "image_" + artefactId + Path.GetExtension(image.FileName);
            // Create user-specific folder structure: Assets/{dir}/{userId}/
            string imageFolder = Path.Combine(BaseAssetsPath, _Dir, userId);

            // Ensure user directory exists
            if (!Directory.Exists(imageFolder))
            {
                Directory.CreateDirectory(imageFolder);
            }

            string filePath = Path.Combine(imageFolder, fileName);

            using (FileStream stream = new FileStream(filePath, FileMode.Create))
            {
                await image.CopyToAsync(stream);
            }
            return $"{_APIEndpoint}{userId}/{fileName}";
        }
        return null;
    }

    /// <summary>
    /// Deletes an image
    /// </summary>
    /// <param name="imgName">The image name (always the GUID) of the owning entity</param>
    /// <param name="dir">Artefact or category dir</param>
    /// <param name="userId">The user ID for locating the file in user-specific folder</param>
    /// <returns>true on sucess, null if image wasn't found</returns>
    public static bool? DeleteImage(string imgName, string dir, string userId)
    {
        _Dir = dir;
        string? file = FindFile(imgName, userId);

        if (file == null) { return null; }

        string path = Path.Combine(BaseAssetsPath, _Dir, userId, file);
        File.Delete(path);

        return true;
    }
    /// <summary>
    /// Locates an image in the filesystem, and returns only the file name (without the extension)
    /// </summary>
    /// <param name="fileName"></param>
    /// <param name="userId">The user ID for searching in user-specific folder</param>
    /// <returns></returns>
    private static string? FindFile(string fileName, string userId)
    {
        string? file = "";
        try
        {
            // Search in user-specific directory: Assets/{dir}/{userId}/
            string path = Path.Combine(BaseAssetsPath, _Dir, userId);//Path.Combine makes the code compatible with all Operating systems (Some OS's uses / for path seperation, while some use \ for path seperation)

            // Ensure user directory exists before searching
            if (!Directory.Exists(path))
            {
                return null;
            }

            // Look for files with "image_" prefix
            var tempfile = Directory.EnumerateFiles(path)
                        .FirstOrDefault(f => Path.GetFileNameWithoutExtension(f).Equals("image_" + fileName, StringComparison.OrdinalIgnoreCase));

            file = tempfile?.Replace(path, "").Remove(0, 1);
        }
        catch (Exception ex)
        {
            // Static utility — ILogger unavailable; use stderr for file-search errors.
            Console.Error.WriteLine($"[ERROR] ImageUtilities.FindImage failed: {ex.Message}");
        }

        // Return the file if found, or null if no match
        return file != null ? file : null;
    }

    /// <summary>
    /// Someone from the frontend added this code, the same yee-yee ass frontend person made it so this wouldn't work because they aren't sending this info in the post requests
    /// </summary>
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