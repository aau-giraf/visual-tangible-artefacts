using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;
using Backendv2.src.API.Routes.artefacts;


var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenAi;
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenAi();
}

app.UseHttpsRedirection();


app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/users")
    .MapUsersRoutes();

app.MapGroup("/users/{id}/boards/{boardid}/images")
    .MapArtefactRoutes();

app.Run();