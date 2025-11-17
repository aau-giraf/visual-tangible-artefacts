namespace VTA.API.Models;

public class Admin : User
{
    // Methods
    public void CreateUser(User user)
    {
        // Implementation for creating a user
    }

    public void DeleteUser(string userId)
    {
        // Implementation for deleting a user
    }

    public void AssignRelation(Relation relation)
    {
        // Implementation for assigning a relation
    }

    public IEnumerable<User> ViewUsers()
    {
        // Implementation for viewing users
        return new List<User>();
    }
}
