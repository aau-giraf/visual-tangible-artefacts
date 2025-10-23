namespace VTA.API.DTOs;

public partial class CategoryPostDTO
{
    public byte? CategoryIndex { get; set; }

    public required Guid UserId { get; set; }

    public string? Name { get; set; }
    public IFormFile? Image { get; set; }
}

public partial class CategoryPatchDTO
{
    public Guid CategoryId { get; set; }

    public byte? CategoryIndex { get; set; }
    public string? Name { get; set; }
    public IFormFile? Image { get; set; }
}

public class CategoryGetDTO
{
    public Guid CategoryId { get; set; }

     public byte? CategoryIndex { get; set; }
     public string? Name { get; set; }
     public string? ImageUrl { get; set; }

     public bool IsDefaultCategory { get; set; } = false;
     public int? UsageCount { get; set; }
     public DateTime? LastUsedDate { get; set; }

     public ICollection<ArtefactGetDTO> Artefacts { get; set; } = new List<ArtefactGetDTO>();
}
