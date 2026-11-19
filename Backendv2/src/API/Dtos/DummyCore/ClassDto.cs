using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class ClassDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int OrganizationId { get; set; }

    public ClassDto() { }
    public ClassDto(Class cls) =>
        (Id, Name, OrganizationId) = (cls.Id, cls.Name, cls.OrganizationId);
}