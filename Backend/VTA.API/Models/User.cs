using VTA.API.Enums;

namespace VTA.API.Models;

public abstract class User
{
    public required string Id { get; set; }

    public required string Password { get; set; }

    public string? FirstName { get; set; }

    public string? LastName { get; set; }

    public required UserRole Role { get; set; }

    // Legacy properties (kept for backward compatibility)
    public string? Name { get; set; }

    public string? GuardianKey { get; set; }

    public string Username { get; set; } = null!;

    // Navigation properties
    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();

    public virtual ICollection<SavedBoard> SavedBoards { get; set; } = new List<SavedBoard>();

    // Method to update profile
    public virtual void UpdateProfile(string? firstName, string? lastName)
    {
        FirstName = firstName;
        LastName = lastName;
    }
}
