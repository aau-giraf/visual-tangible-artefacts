namespace Backendv2.src.API.Routes;

public static class boardsRoutes
{
    public static RouteGroupBuilder MapBoardsRoutes(this RouteGroupBuilder group)
    {
        //Get all boards for a user
        group.MapGet("/", () => "Hello from Boards!");
        group.MapGet("/{boardId}", (int boardId) => $"Hello from Boards with id: {boardId}");
        group.MapPost("/", () => "Hello from Boards POST!");

        return group;
    }
}