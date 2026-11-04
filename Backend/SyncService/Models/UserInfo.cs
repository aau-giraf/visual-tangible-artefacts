namespace SyncService.Models;

//Used for having info on a user in the format of name and id. 
public class UserInfo
{
    public required string UserId { get; set; }
    public required string Name { get; set; }
}