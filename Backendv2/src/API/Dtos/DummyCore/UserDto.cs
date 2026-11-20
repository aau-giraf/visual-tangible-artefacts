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