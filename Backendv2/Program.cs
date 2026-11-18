using Backendv2.DB.Data.Models.DummyCoreModels;
using Backendv2.DB.Data.Models.VTAModels;
using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.artefacts;
using Backendv2.src.API.Routes.Users;
using DotNetEnv;
using Microsoft.EntityFrameworkCore;

//Used to get the information from the .env file 
Env.TraversePath().Load();


var builder = WebApplication.CreateBuilder(args);


//Adds the VTA databse context to the application 
builder.Services.AddDbContext<VtaContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("VTAConnectionString"))
        .LogTo(Console.WriteLine, LogLevel.Information)); // prints SQL to console

builder.Services.AddDbContext<DummyCoreContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DummyCoreConnectionString"))
        .LogTo(Console.WriteLine, LogLevel.Information)); // prints SQL to console



var app = builder.Build();

app.UseHttpsRedirection();

// Temporary DB smoke tests (only in Development)
if (app.Environment.IsDevelopment())
{
    app.UseTempDebug();

    app.MapGroup("/dbtest")
        .MapDbTestRoutes();
}


app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/users")
    .MapUsersRoutes();

app.MapGroup("/users/{id}/boards/{boardid}/images")
    .MapArtefactRoutes();

app.Run();


