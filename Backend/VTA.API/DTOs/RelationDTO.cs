namespace VTA.API.DTOs;

public class CreatePairingRequest
{
    public required string CaregiverId { get; set; }
    public required string ChildId { get; set; }
}

public class PairingGetDTO
{
    public string Id { get; set; } = string.Empty;
    public string CaregiverId { get; set; } = string.Empty;
    public string ChildId { get; set; } = string.Empty;
    public UserGetDTO? Caregiver { get; set; }
    public UserGetDTO? Child { get; set; }
    public DateTime CreatedAt { get; set; }
}