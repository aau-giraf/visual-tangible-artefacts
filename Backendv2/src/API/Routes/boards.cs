namespace Backendv2.src.API.Routes;

public static class boardsRoutes
{
    public static void MapBoardsRoutes(WebApplication app)
    {
        app.MapGet("/boards", () => "Hello from Boards!");

        
    }
}