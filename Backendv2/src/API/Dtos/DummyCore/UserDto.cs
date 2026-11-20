using Backendv2.DB.Data.Models.DummyCoreModels;

namespace Backendv2.src.API.DTOs.DummyCore;


public class UserDto
{
    public int Id { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string UserName { get; set; } = null!;
    public string Password { get; set; } = null!;

    public UserDto() { }
    public UserDto(User user) =>
        (Id, FirstName, LastName, UserName, Password) = (user.Id, user.FirstName, user.LastName, user.UserName, user.Password);
}

// Composite DTO: This is the user that is sent to VTA.
// Tables:
//  User:       Id, UserName, FirstName, LastName
//  NonCitizen: Email (User.NonCitizen)
//  UserRole:   Role (NonCitizen.UserRoles)
//  Citizen:    no columns used, only checked for existence: Role = "citizen" if present
public record UserDetailsDto(
    int Id,
    string UserName,
    string? Email,
    string? FirstName,
    string? LastName,
    string? Role);


// Request DTO: This is the user that is sent from VTA to create a user. Input only, never returned from an endpoint.
// Tables:
//  User:       UserName, Password, FirstName, LastName
//  NonCitizen: Email (only for non-citizens; ignored for citizens)
//  UserRole:   Role + OrganizationId (non-citizens only)
//  Citizen:    ClassId (only when Role = "citizen")
public record CreateUserDto(
    string UserName,
    string Password,
    string? Email,
    string? FirstName,
    string? LastName,
    string Role,
    int? OrganizationId,
    int? ClassId);