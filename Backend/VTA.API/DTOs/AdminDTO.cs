namespace VTA.API.DTOs;

public class PairingDTO
{
    public string Id { get; set; } = null!;
    public string CaregiverId { get; set; } = null!;
    public string ChildId { get; set; } = null!;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public UserGetDTO? Caregiver { get; set; }
    public UserGetDTO? Child { get; set; }
}

public class CreatePairingDTO
{
    public required string CaregiverId { get; set; }
    public required string ChildId { get; set; }
}