namespace Vta.Pairings;

public class CaregiverChildPairing
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaregiverId { get; set; }
    public Guid ChildId { get; set; }
    public bool IsActive { get; set; } = true;
}