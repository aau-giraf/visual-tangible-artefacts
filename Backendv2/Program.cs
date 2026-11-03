using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;
using Backendv2.src.API.Routes.artefacts;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/users")
    .MapUsersRoutes();

app.MapGroup("/users/{id}/boards/{boardid}/images")
    .MapArtefactRoutes();

app.Run();