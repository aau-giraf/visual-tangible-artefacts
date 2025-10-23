using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;

namespace VTA.API.Models.Users;

public class User
{
    public required Guid Id { get; set; }

    public string? Name { get; set; }

    public required string Password { get; set; }

    public string? GuardianKey { get; set; }

    public string Username { get; set; } = null!;

    public virtual ICollection<UserArtefact> Artefacts { get; set; } = new List<UserArtefact>();

    public virtual ICollection<UserCategory> Categories { get; set; } = new List<UserCategory>();
}
