namespace VTA.API.Models;

public abstract class Category
{
    public required string CategoryId { get; set; }
    public byte? CategoryIndex { get; set; }
    public string? Name { get; set; }
    public string? ImagePath { get; set; }
    public DateTime? ModifiedDate { get; set; }
    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();
}
