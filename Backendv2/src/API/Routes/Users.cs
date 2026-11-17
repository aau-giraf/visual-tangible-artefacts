using Backendv2.DB.Data;
using Backendv2.src.API.Controllers;
using Backendv2.src.API.Controllers.usersettingsController;


namespace Backendv2.src.API.Routes.Users;


public static class usersRoutes
{
    public static RouteGroupBuilder MapUsersRoutes(this RouteGroupBuilder group)
    {
        // GET: /users
        // Get all users
        // TODO : Implement logic to get all users
        //User person1 = new(1,"Jonas","jonas@myass.ai","jonas","Pederson","sidekick");
        //User person2 = new(2,"Lasse","lasse@myass.ai","Lasse","Kreiner","Not sidekick");
        //group.MapGet("/", () => UserController.GetAll(person1, person2));

        // POST: users/auth/register
        // Register a user 
        // TODO : implemenmt logic so register a user
        group.MapPost("/auth/register", () => "controller.Create()");
        
        // GET: /users/{id}
        // Get specific user by id
        // TODO : implemnet logic to get a specific user by id
        group.MapGet("/{userId}", (int userId) => "controller.GetByid(userId)");

        // PATCH: /users/{id}
        // Update a specic user
        // TODO : implement logic to update a specific user
        group.MapPatch("/{userId}", (int userId) => "controller");

         // DELETE: /users/{id}
        // Delete a specific user
        // TODO : implement logic to delete specific user
        group.MapDelete("/{userId}", (int userId) => "controller.Delete(userId)");
        
        
        // PUT: /users/{id}/password
        // Specific user can change password
        // TODO : implement lofic so specific user can change password
        group.MapPut("/{userId}/password", (int userId) => "controller");
        
        // GET: /users/{id}/settings
        // Get user settings
        group.MapGet("/{UserId}/settings", (int UserId, VtaDevContext Db) => (
            UserSettingsController.GetUserSettings(UserId, Db)
        ));
        
        // PATCH: /users/{id}/settings
        // Update user settings
        group.MapPatch("/{userId}/settings", (int userId) => "controller");

        //Return group so it can be used in the program.cs file
        return group;

    }
} 
    