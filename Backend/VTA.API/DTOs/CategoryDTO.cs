namespace VTA.API.DTOs;

public partial class CategoryPostDTO
{
    public byte? CategoryIndex { get; set; }

    public required string UserId { get; set; }

    public string? Name { get; set; }
}

public partial class CategoryGetDTO
{
    public string CategoryId { get; set; } = null!;

    public byte? CategoryIndex { get; set; }

    public string? Name { get; set; }

    public virtual ICollection<ArtefactGetDTO> Artefacts { get; set; } = new List<ArtefactGetDTO>();
}
