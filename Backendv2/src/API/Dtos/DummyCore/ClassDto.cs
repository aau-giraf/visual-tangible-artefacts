using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class ClassDto
{
    public int Id { get; set; }
    public string name { get; set; }
    public int organizationId { get; set; }

    ClassDto() { }
    public ClassDto(Class @class) => (Id, name, organizationId) = (@class.Id, @class.name, @class.organizationId);
}