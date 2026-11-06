using Backendv2.src.API.Routes;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();


app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/hello")
    .MapHelloRoutes();

app.Run();