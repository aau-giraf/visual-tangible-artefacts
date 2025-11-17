using VTA.API.Enums;

namespace VTA.API.Models;

public class Caregiver : User
{
    public RelationType? RelationType { get; set; }

    // Navigation properties
    public virtual ICollection<Relation> CaregiverRelations { get; set; } = new List<Relation>();

    // Methods
    public void InitiateConnection(Child child, RelationType relationType)
    {
        // Implementation for initiating a connection with a child
    }

    public bool AuthenticateUserChange(string guardianKey)
    {
        // Implementation for authenticating user changes
        return GuardianKey == guardianKey;
    }
}
