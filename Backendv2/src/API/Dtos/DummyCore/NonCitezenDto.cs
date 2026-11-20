using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;

public class NonCitezenDto
{
    public int Id { get; set; }
    public string? Email { get; set; }

    public NonCitezenDto() { }
    public NonCitezenDto(NonCitizen nonCitizen) =>
        (Id, Email) = (nonCitizen.Id, nonCitizen.Email);
}