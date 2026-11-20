using Backendv2.src.API.Handlers.DummyCoreHandler;

namespace Backendv2.src.API.Routes.DummyCore
{
    public static class DummyUsersRoutes
    {
        public static RouteGroupBuilder MapDummyCoreUsersRoutes(this RouteGroupBuilder group)
        {
            // GET: /dummycore/get/userId=1
            // Get a specific user by id (User + NonCitizen + UserRole)
            // Returns 404 if the user does not exist
            group.MapGet("/get/userId={userId:int}", DummyCoreUserHandler.GetById);

            // GET: /dummycore/get/users
            // Get all users (User + NonCitizen + UserRole)
            group.MapGet("/get/users", DummyCoreUserHandler.GetAll);

            // Return group so it can be used in the Program.cs file
            return group;
        }
    }
}