using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class UserRoleDto
{
    public int NonCitizenId { get; set; }
    public int OrganizationId { get; set; }
    public string Role { get; set; } = null!;

    public UserRoleDto() { }
    public UserRoleDto(UserRole userRole) =>
        (NonCitizenId, OrganizationId, Role) = (userRole.NonCitizenId, userRole.OrganizationId, userRole.Role);
}