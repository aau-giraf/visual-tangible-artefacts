namespace VTA.API.Models;

public class UserCategory : Category
{
    public int UsageCount { get; set; } = 0;
    public DateTime? LastUsedDate { get; set; }
    
    public required string UserId { get; set; } = null!;
    public virtual User User { get; set; } = null!;
}