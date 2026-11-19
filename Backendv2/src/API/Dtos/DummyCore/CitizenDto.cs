using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class CitizenDto
{
    public int Id { get; set; }
    public string email { get; set; }

    public CitizenDto() { }
    public CitizenDto(Citizen citizen) =>
    (Id, email) = (citizen.Id, citizen.email);
}