namespace VTA.Data.Models;

//Entity Framework Core entity model that represents call status stored in the application's database.
public enum CallStatus
{
    Pending,
    Accepted,
    Rejected,
    InProgress,
    Completed,
    Failed
}
