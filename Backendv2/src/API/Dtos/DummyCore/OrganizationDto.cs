using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class OrganizationDto
{
    public string? Name { get; set; }

    public OrganizationDto() { }
    public OrganizationDto(Organization organization) =>
        (Name) = (organization.Name);

}