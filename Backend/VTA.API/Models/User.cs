namespace VTA.API.Models;

public class User
{
    public required string Id { get; set; }

    public string? Name { get; set; }

    public required string Password { get; set; }

    public string Username { get; set; } = null!;

    public UserRole Role { get; set; } = UserRole.Child;

    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();

    public virtual ICollection<SavedBoard> SavedBoards { get; set; } = new List<SavedBoard>();

    public virtual ICollection<CaregiverChildPairing> CaregiverPairings { get; set; } = new List<CaregiverChildPairing>();

    public virtual ICollection<CaregiverChildPairing> ChildPairings { get; set; } = new List<CaregiverChildPairing>();

    public virtual ICollection<Session> CaregiversSessions { get; set; } = new List<Session>();

    public virtual ICollection<Session> ChildSessions { get; set; } = new List<Session>();
}
