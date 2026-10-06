using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Extensions;

//Mainly responsible for setting up the database when applications starts.
public static class WebApplicationExtensions
{
    public static async Task<WebApplication> MigrateVTAContext(this WebApplication application)
    {
        const string environmentKey = "AUTO_CREATE_DATABASE";


    
        var environmentVariable = Environment.GetEnvironmentVariable(environmentKey);
        //Automatic database creation is enabled when variable is missing/empty or set to true.
        var autoCreateDb = string.IsNullOrWhiteSpace(environmentVariable) || bool.Parse(environmentVariable);

        //If enviroment varible is set to false, database setup is skipped.
        if (!autoCreateDb) return application;
        
        await using var scope = application.Services.CreateAsyncScope();

        try
        {
            var vtaContext = await scope.MigrateVTAContext(); //Brings database schema up to date


            await vtaContext.SeedTestUser(); //adds initial/test user data


            await vtaContext.SaveChangesAsync(); //Saves changes to database.
        }
        catch (Exception ex)
        {
            var logger = application.Services.GetRequiredService<ILoggerFactory>()
                .CreateLogger(nameof(WebApplicationExtensions));
            logger.LogError(ex, "Error creating database schema");
            throw;
        }

        return application;
    }

    //Helper method for getting the database context and making sure database exists.
    private static async Task<VTAContext> MigrateVTAContext(this IServiceScope scope)
    {
        var vtaContext = scope.ServiceProvider.GetRequiredService<VTAContext>();
        await vtaContext.Database.EnsureCreatedAsync();
        
        return vtaContext;
    }


    //Method is responsible for seeding the database with test users and creating cargiver-child pairing between them.
    private static async Task<VTAContext> SeedTestUser(this VTAContext context)
    {
        const string giraf = "giraf";
        var girafUser = await context.Users.FirstOrDefaultAsync(u => u.Username == giraf);
        if (girafUser is null)
        {
            girafUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = giraf,
                Password = BCrypt.Net.BCrypt.HashPassword(giraf),
                Username = giraf,
                Role = UserRole.Child
            };
            context.Users.Add(girafUser);
        }

        const string admin = "admin";
        var adminUser = await context.Users.FirstOrDefaultAsync(u => u.Username == admin);
        if (adminUser == null)
        {
            adminUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Admin User",
                Password = BCrypt.Net.BCrypt.HashPassword(admin),
                Username = admin,
                Role = UserRole.Admin
            };
            context.Users.Add(adminUser);
        }
        else if (adminUser.Role != UserRole.Admin)
        {
            adminUser.Role = UserRole.Admin;
        }

        const string caregiver = "caregiver";
        var caregiverUser = await context.Users.FirstOrDefaultAsync(u => u.Username == caregiver);
        if (caregiverUser is null )
        {
            caregiverUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Test Caregiver",
                Password = BCrypt.Net.BCrypt.HashPassword(caregiver),
                Username = caregiver,
                Role = UserRole.Caregiver
            };
            context.Users.Add(caregiverUser);
        }

        var relation = await context.Relations.FirstOrDefaultAsync(ur => ur.CaregiverId == caregiverUser.Id && ur.ChildId == girafUser.Id);
        if (relation is null)
        {
            relation = new Relation
            {
                Id = Guid.NewGuid().ToString(),
                CaregiverId = caregiverUser.Id,
                ChildId = girafUser.Id,
            };

            context.Relations.Add(relation);
        }

        return context;
    }
}