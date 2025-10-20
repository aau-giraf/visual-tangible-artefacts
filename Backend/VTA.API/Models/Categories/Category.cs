using VTA.API.Models.Artefacts;

namespace VTA.API.Models.Categories;

public abstract class Category
{
    public required string CategoryId { get; set; }
    public byte? CategoryIndex { get; set; }
    public string? Name { get; set; }
    public string? ImagePath { get; set; }
    public DateTime? ModifiedDate { get; set; }

    // Remove base collection - derived classes will have their specific artefact collections
}
