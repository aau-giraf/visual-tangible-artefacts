using Backendv2.src.API.Routes;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

boardsRoutes.MapBoardsRoutes(app);

app.Run();