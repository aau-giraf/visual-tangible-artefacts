namespace VTA.API.Utilities;

public static class ImageUtilities
{
    private static string _APIEndpoint = "/api/Assets";
    private static string _Dir = "Assets";

    public static string? AddImage(IFormFile? image, string artefactId)
    {
        if (image != null && image.Length > 0)
        {
            string fileName = artefactId + Path.GetExtension(image.FileName);
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
}