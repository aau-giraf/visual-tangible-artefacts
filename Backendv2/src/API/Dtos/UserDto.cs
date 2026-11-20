using Backendv2.DB.Data;

namespace Backendv2.src.API.DTOs.UserDto;

public class UserDto
{
    public int Id {get; set;}

    public UserDto() { }
    public UserDto(User User) =>
    (Id) = (User.Id);
}