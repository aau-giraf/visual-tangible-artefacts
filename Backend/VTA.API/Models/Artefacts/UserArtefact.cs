using VTA.API.Models.Categories;
using VTA.API.Models.Users;

namespace VTA.API.Models.Artefacts;

public class UserArtefact : Artefact
{
    public virtual UserCategory? Category { get; set; }

    public required string UserId { get; set; }
    public virtual User User { get; set; } = null!;
}