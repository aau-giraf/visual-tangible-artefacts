using Backendv2.DB.Data;

namespace Backendv2.src.API.Routes.DTOs.LocalUserDto;

public class LocalUserDto()
{
    public int Id {get; set;}

    public LocalUserDto() { }
    public LocalUserDto( LocalUser LocalUser) =>
    (Id) = (LocalUser.Id);
}