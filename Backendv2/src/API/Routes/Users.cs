
namespace Backendv2.src.API.Routes.Users;

public static class usersRoutes
{
    public static RouteGroupBuilder MapUsersRoutes(this RouteGroupBuilder group)
    {
        // GET: api/Users
        // Get all users
        // TODO : Implement logic to get all users
        group.MapGet("/", () => "controller.GetAll()");

        // GET: api/Users/{id}
        // Get specific user by id
        // TODO : implemnet logic to get a specific user by id
        group.MapGet("/{userId}", (int userId) => "controller.GetByid(userId)");

        // POST: /auth/register
        // Register a user 
        // TODO : implemenmt logic so register a user
        group.MapPost("/auth/register", () => "controller.Create()");

        // PATCH: /users/{id}
        // Ubdate a specic user
        // TODO : implement logic to ubdate a specific user
        group.MapPatch("/{userId}", (int userId) => "controller");

        // PUT: /users/{id}/password
        // Specific user can change password
        // TODO : implement lofic so specific user can change password
        group.MapPut("/{userId}/password", (int userId) => "controller");
        
        // DELETE: /users/{id}
        // Delete a specific user
        // TODO : implement logic to delete specific user
        group.MapDelete("/{userId}", (int userId) => "controller.Delete(userId)");
        
        // GET: /users/{id}/settings
        // Get user settings
        // TODO : implement logic to get user settings
        group.MapGet("/{userId}/settings", (int userId) => "controller");
        
        // PATCH: /users/{id}/settings
        // Ubdate user settings
        // TODO : implement logic to ubdate user settings
        group.MapPatch("/{userId}/settings", (int userId) => "controller");


        //Return group so it can be used in the program.cs file
        return group;

    }
} 
    