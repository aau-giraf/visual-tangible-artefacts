namespace VTA.API.Models;

public class Child : User
{
    // Navigation properties
    public virtual ICollection<Relation> ChildRelations { get; set; } = new List<Relation>();

    // Methods
    public void AcceptConnection(Relation relation)
    {
        // Implementation for accepting a connection
    }

    public void DenyConnection(Relation relation)
    {
        // Implementation for denying a connection
    }
}
