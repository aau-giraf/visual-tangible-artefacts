using VTA.API.Enums;

namespace VTA.API.Models;

public class Relation
{
    public required string RelationId { get; set; }

    public required string StudentId { get; set; }

    public required string RelativeId { get; set; }

    public required RelationType RelationType { get; set; }

    public required RelationStatus Status { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Child Student { get; set; } = null!;

    public virtual Caregiver Relative { get; set; } = null!;

    public virtual Invite? Invite { get; set; }

    public virtual ICollection<Session> Sessions { get; set; } = new List<Session>();
}
