namespace VTA.API.Models;

public class Session
{
    public int Id { get; set; }

    public required string CaregiverId { get; set; }

    public required string ChildId { get; set; }

    public CallStatus CallStatus { get; set; }

    public virtual User Caregiver { get; set; } = null!;

    public virtual User Child { get; set; } = null!;
}
