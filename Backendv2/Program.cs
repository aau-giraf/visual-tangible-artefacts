using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;


var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

<<<<<<< HEAD
<<<<<<< HEAD

app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

=======
=======
>>>>>>> c25a6e3f2ed7c571a8099d2988e4ee7366936cd0
app.MapGroup("/users")
    .MapUsersRoutes();

boardsRoutes.MapBoardsRoutes(app);
>>>>>>> 4f0efb5 (something)


    


    

app.Run();