using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class CitizenDto
{
    public int Id { get; set; }
    public int ClassId { get; set; }

    public CitizenDto() { }
    public CitizenDto(Citizen citizen) =>
        (Id, ClassId) = (citizen.Id, citizen.ClassId);
}