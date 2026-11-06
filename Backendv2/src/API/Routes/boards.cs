namespace Backendv2.src.API.Routes;

public static class boardsRoutes
{
    public static RouteGroupBuilder MapBoardsRoutes(this RouteGroupBuilder group)
    {
        //Get all boards for a user
        //TODO : Implement logic to get all boards for a user
        group.MapGet("/", () => "Hello from Boards!");

        //Get a specific board by id
        //TODO : Implement logic to get a specific board by id
        group.MapGet("/{boardId}", (int boardId) => $"Hello from Boards with id: {boardId}");

        //Create a new board for a user
        //TODO : Implement logic to create a new board for a user
        group.MapPost("/", () => "Hello from Boards POST!");

        //return the group so that it can be used in the Program.cs file
        return group;
    }
}