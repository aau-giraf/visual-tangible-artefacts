using Backendv2.DB.Data;
using Backendv2.src.API.Routes;
using Backendv2.src.API.Routes.Users;
using Backendv2.src.API.Routes.artefacts;
using Microsoft.EntityFrameworkCore;
using DotNetEnv;

//Used to get the information from the .env file 
Env.TraversePath().Load();


var builder = WebApplication.CreateBuilder(args);

Console.WriteLine($"Conn string: {builder.Configuration.GetConnectionString("VTAConnectionString") ?? "NOT FOUND"}");

//Adds the VTA databse context to the application 
builder.Services.AddDbContext<VtaDevContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("VTAConnectionString"))
           .LogTo(Console.WriteLine, LogLevel.Information)); // prints SQL to console

           

var app = builder.Build();

app.UseHttpsRedirection();

// Temporary CRUD smoke test
app.MapGet("/dbtest", async (VtaDevContext dbvta) =>
{
    var log = new List<string>();
    void Step(string msg) { Console.WriteLine(msg); log.Add(msg); }

    try
    {
        Step($"Can connect: {await dbvta.Database.CanConnectAsync()}");

        // Create (Id is ValueGeneratedNever, so we set it ourselves)
        Step("Inserting a new board");
        var board = new Board { Id = 9999, Name = "test board", UserId = 1 };
        dbvta.Add(board);
        await dbvta.SaveChangesAsync();

        // Read
        Step("Querying for the board");
        var found = await dbvta.Boards
            .OrderBy(b => b.Id)
            .FirstAsync(b => b.Id == 9999);
        Step($"Found board: {found.Id} / {found.Name}");

        // Update
        Step("Updating the board name");
        found.Name = "renamed test board";
        await dbvta.SaveChangesAsync();

        // Delete
        Step("Deleting the board");
        dbvta.Remove(found);
        await dbvta.SaveChangesAsync();

        Step("All steps passed");
        return Results.Ok(log);
    }
    catch (Exception ex)
    {
        Step($"FAILED: {ex.GetBaseException().Message}");
        return Results.Problem(string.Join("\n", log));
    }
});

app.MapGroup("/users/{id}/boards")
    .MapBoardsRoutes();

app.MapGroup("/users")
    .MapUsersRoutes();

app.MapGroup("/users/{id}/boards/{boardid}/images")
    .MapArtefactRoutes();

app.Run();