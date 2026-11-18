namespace Backendv2.DB.Data.Models.DummyCoreModels;

public partial class Image
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public int CitizenId { get; set; }

    public string? Path { get; set; }

    public int OrganizationId { get; set; }

    public string StorageKey { get; set; } = null!;

    public string FileName { get; set; } = null!;

    public string FileType { get; set; } = null!;

    public long SizeBytes { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Citizen Citizen { get; set; } = null!;

    public virtual Organization Organization { get; set; } = null!;
}
