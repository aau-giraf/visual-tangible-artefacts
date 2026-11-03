using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

<<<<<<< HEAD

app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

=======
app.MapGroup("/users")
    .MapUsersRoutes();

boardsRoutes.MapBoardsRoutes(app);
>>>>>>> 4f0efb5 (something)


    

app.Run();