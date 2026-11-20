using Backendv2.DB.Data.Models.VTAModels;

namespace Backendv2.src.API.DTOs;

public class UserDto
{
    public int Id {get; set;}

    public UserDto() { }
    public UserDto(UserVta User) =>
    (Id) = (User.Id);
}