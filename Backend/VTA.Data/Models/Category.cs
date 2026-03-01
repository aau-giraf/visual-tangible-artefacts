namespace VTA.Data.Models;

public class Category
{
    public required string CategoryId { get; set; }
    public byte? CategoryIndex { get; set; }
    public required int UserId { get; set; }
    public string? Name { get; set; }
    public string? ImagePath { get; set; }
    public DateTime? ModifiedDate { get; set; }
    public int UsageCount { get; set; } = 0;
    public DateTime? LastUsedDate { get; set; }
    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();
}
