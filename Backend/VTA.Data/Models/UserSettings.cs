namespace VTA.Data.Models;

public class UserSettings
{
    public required int UserId { get; set; }
    public bool NameVisible { get; set; } = false;
    public int FieldCount { get; set; } = 4;
}
