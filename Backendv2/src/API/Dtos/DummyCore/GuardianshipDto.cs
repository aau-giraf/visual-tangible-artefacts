using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class GuardianshipDto
{
    public int CitezenId { get; set; }
    public int GuardianId { get; set; }

    GuardianshipDto() { }
    public GuardianshipDto(Guardianship guardianship) =>
        (CitizenId, GuardianId) = (guardianship.CitizenId, guardianship.GuardianId);
}