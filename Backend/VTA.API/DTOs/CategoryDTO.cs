namespace VTA.API.DTOs;

public partial class CategoryPostDTO
{
    public string? CategoryId { get; set; }
    
    public byte? CategoryIndex { get; set; }

    public required int UserId { get; set; }

    public string? Name { get; set; }
    public IFormFile? Image { get; set; }
}

public partial class CategoryPatchDTO
{
    public string CategoryId { get; set; }

    public byte? CategoryIndex { get; set; }
    public string? Name { get; set; }
    public IFormFile? Image { get; set; }
}

public partial class CategoryGetDTO
{
    public string CategoryId { get; set; } = null!;

    public byte? CategoryIndex { get; set; }

    public string? Name { get; set; }
    public string? ImageUrl { get; set; }
    public int UsageCount { get; set; } = 0;
    public DateTime? LastUsedDate { get; set; }

    public virtual ICollection<ArtefactGetDTO> Artefacts { get; set; } = new List<ArtefactGetDTO>();
}
