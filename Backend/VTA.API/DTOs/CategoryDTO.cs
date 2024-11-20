namespace VTA.API.DTOs;

public partial class CategoryPostDTO
{
    public byte? CategoryIndex { get; set; }

    public required string UserId { get; set; }

    public string? Name { get; set; }
    public required IFormFile Image { get; set; }
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

    public virtual ICollection<ArtefactGetDTO> Artefacts { get; set; } = new List<ArtefactGetDTO>();
}
