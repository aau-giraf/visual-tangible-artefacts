using VTA.API.Models.Artefacts;
using VTA.API.Models.Users;

namespace VTA.API.Models.Categories;

public class UserCategory : Category
{
    public int UsageCount { get; set; } = 0;
    public DateTime? LastUsedDate { get; set; }

    public required string UserId { get; set; } = null!;
    public virtual User User { get; set; } = null!;

    public virtual ICollection<UserArtefact> Artefacts { get; set; } = new List<UserArtefact>();
}