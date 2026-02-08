using VTA.API.Utilities;

namespace VTA.API.Services;

/// <summary>
/// Default implementation of <see cref="IImageService"/>.
/// Delegates to the static <see cref="ImageUtilities"/> methods.
/// Registered as scoped in DI so consumers can be tested with a mock.
/// </summary>
public class ImageService : IImageService
{
    /// <inheritdoc />
    public Task<string?> AddImageAsync(IFormFile? image, string entityId, string directory, string userId)
    {
        return ImageUtilities.AddImage(image, entityId, directory, userId);
    }

    /// <inheritdoc />
    public bool? DeleteImage(string entityId, string directory, string userId)
    {
        return ImageUtilities.DeleteImage(entityId, directory, userId);
    }
}
