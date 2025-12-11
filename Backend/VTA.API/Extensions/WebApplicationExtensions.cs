using Microsoft.EntityFrameworkCore;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Extensions;

public static class WebApplicationExtensions
{
    public static async Task<WebApplication> MigrateVTAContext(this WebApplication application)
    {
        const string environmentKey = "AUTO_CREATE_DATABASE";


        var environmentVariable = Environment.GetEnvironmentVariable(environmentKey);
        var autoCreateDb = string.IsNullOrWhiteSpace(environmentVariable) || bool.Parse(environmentVariable);

        if (!autoCreateDb) return application;
        
        await using var scope = application.Services.CreateAsyncScope();

        try
        {
            var vtaContext = await scope.MigrateVTAContext();


            await vtaContext.SeedTestUser();


            await vtaContext.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating database schema: {ex.Message}");
            throw;
        }

        return application;
    }

    private static async Task<VTAContext> MigrateVTAContext(this IServiceScope scope)
    {
        var vtaContext = scope.ServiceProvider.GetRequiredService<VTAContext>();
        await vtaContext.Database.EnsureCreatedAsync();
        
        return vtaContext;
    }

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