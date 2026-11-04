namespace VTA.Data.Models;

//Entity Framework Core entity model that represents a relation stored in the application's database.
public class Relation
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public required string CaregiverId { get; set; }
    public required string ChildId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public virtual User Caregiver { get; set; } = null!;
    public virtual User Child { get; set; } = null!;
}