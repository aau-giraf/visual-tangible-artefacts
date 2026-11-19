using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;

public class ImageDto
{
    public int Id { get; set; }
    public string? Name { get; set; }
    public int CitizenId { get; set; }
    public string? Path { get; set; }
    public int OrganizationId { get; set; }
    public string StorageKey { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public string FileType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public DateTime? CreatedAt { get; set; }

    public ImageDto() { }
    public ImageDto(Image image) =>
        (Id, Name, CitizenId, Path, OrganizationId, StorageKey, FileName, FileType, SizeBytes, CreatedAt) =
        (image.Id, image.Name, image.CitizenId, image.Path, image.OrganizationId, image.StorageKey,
         image.FileName, image.FileType, image.SizeBytes, image.CreatedAt);
}