namespace VTA.API.DTOs;

//Used when client wants to create a new pairing between cargiver and child.
public class CreatePairingRequest
{
    //Both cargiver id and child id are required for creating pairing.
    public required string CaregiverId { get; set; }
    public required string ChildId { get; set; }
}

//Used when API wants to send information about existing pairing back to client.
public class PairingGetDTO
{
    public string Id { get; set; } = string.Empty; //Contains pairings own id
    public string CaregiverId { get; set; } = string.Empty;
    public string ChildId { get; set; } = string.Empty;

    //Contains actual user information
    public UserGetDTO? Caregiver { get; set; }
    public UserGetDTO? Child { get; set; }

    public DateTime CreatedAt { get; set; } //Contains date for when pairing was created.
}