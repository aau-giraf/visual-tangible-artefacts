using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGroup("/users")
    .MapUsersRoutes();

boardsRoutes.MapBoardsRoutes(app);


    

app.Run();