using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/users")
    .MapUsersRoutes();

app.Run();