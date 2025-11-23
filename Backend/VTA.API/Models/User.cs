namespace VTA.API.Models;

public class User
{
    public required string Id { get; set; }

    public string? Name { get; set; }

    public required string Password { get; set; }

    public string Username { get; set; } = null!;

    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();

    public virtual ICollection<SavedBoard> SavedBoards { get; set; } = new List<SavedBoard>();

    public UserRole Role { get; set; } = UserRole.Child;

    public virtual ICollection<Relation> CaregiverRelations { get; set; } = new List<Relation>();

    public virtual ICollection<Relation> ChildRelations { get; set; } = new List<Relation>();
}
