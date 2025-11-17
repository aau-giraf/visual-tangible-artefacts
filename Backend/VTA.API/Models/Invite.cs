using VTA.API.Enums;

namespace VTA.API.Models;

public class Invite
{
    public int InviteId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public required DateTime ExpiresAt { get; set; }

    public required string CreatedBy { get; set; }

    public required string RelationId { get; set; }

    public required InviteStatus InviteStatus { get; set; }

    // Navigation properties
    public virtual User Creator { get; set; } = null!;

    public virtual Relation Relation { get; set; } = null!;

    public virtual Session? Session { get; set; }
}
