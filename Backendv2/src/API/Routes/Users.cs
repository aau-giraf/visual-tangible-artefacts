using Microsoft.AspNetCore.Http;

namespace Backendv2.src.API.Routes.Users;


public static class usersRoutes()
{
    public static RoutesGroupBuilder MapUsersRoutes(this RouteGroupBuilder group)
    {
        // GET: api/Users
        // Get all users
        group.MapGet("/", () => controller.GetAll());

        // GET: api/Users/{id}
        group.MapGet("/{userId}", (int userId) => controller.GetByid(userId));

        //POST: /auth/register
        group.MapPost("/auth/register", () => controller.Create());

        //PATCH: /users/{id}
        group.MapPatch("/{userId}", () => controller);

        //PUT: /users/{id}/password
        group.MapPut("/{userId}/password", () => controller);
        
        //DELETE: /users/{id}
        group.MapDelete("/{userId}", (int userId) => controller.Delete(userId));
        
        //GET: /users/{id}/settings
        group.MapGet("/{userId}/settings", () => controller);
        
        //PATCH: /users/{id}/settings
        group.MapPatch("/{userId}/settings", () => controller);


        return group;

    }
}









    
    