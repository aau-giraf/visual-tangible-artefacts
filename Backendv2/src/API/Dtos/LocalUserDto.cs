using Backendv2.DB.Data;

namespace Backendv2.src.API.DTOs;

public class LocalUserDto
{
    public int Id {get; set;}

    public LocalUserDto() { }
    public LocalUserDto( LocalUser LocalUser) =>
    (Id) = (LocalUser.Id);
}