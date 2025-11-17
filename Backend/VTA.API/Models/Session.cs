using VTA.API.Enums;

namespace VTA.API.Models;

public class Session
{
    public required string Id { get; set; }

    public int? InviteId { get; set; }

    public required string RelationId { get; set; }

    public string? BoardId { get; set; }

    public required SessionStatus Status { get; set; }

    // Navigation properties
    public virtual Invite? Invite { get; set; }

    public virtual Relation Relation { get; set; } = null!;

    public virtual SavedBoard? Board { get; set; }
}
