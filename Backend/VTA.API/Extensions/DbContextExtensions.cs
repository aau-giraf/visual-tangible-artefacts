using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.Models;

namespace VTA.API.Extensions;

#pragma warning disable CS1591

public static class DbContextExtensions
{
    public static WebApplicationBuilder AddVTAContext(this WebApplicationBuilder builder)
    {
        const string connectionType = "DefaultConnection";

        builder.Services.AddDbContext<VTAContext>(opt =>
        {
            try
            {
                opt.UseMySql(
                    builder.Configuration.GetConnectionString(connectionType),
                    ServerVersion.AutoDetect(builder.Configuration.GetConnectionString(connectionType)),
                    options =>
                    {
                        options.EnableStringComparisonTranslations();
                        options.EnableRetryOnFailure();
                    }
                );
            }
            catch (Exception e)
            {
                Console.WriteLine($"An error occurred while configuring MySQL: {e.Message}\n\n Falling Back to a volatile DB");
            }
        });
        return builder;
    }

    public static async Task<WebApplication> MigrateVTAContext(this WebApplication app)
    {
        const string environmentKey = "AUTO_CREATE_DATABASE";

        var environmentVariable = Environment.GetEnvironmentVariable(environmentKey);
        var autoCreateDb = !string.IsNullOrWhiteSpace(environmentVariable) && bool.Parse(environmentVariable);

        if (!autoCreateDb) return app;

        using var scope = app.Services.CreateScope();

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

        return app;
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
        var testUserExist = await context.Users.AnyAsync(u => u.Username == giraf);
        if (!testUserExist)
        {
            var testUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = giraf,
                Password = BCrypt.Net.BCrypt.HashPassword(giraf),
                Username = giraf,
                Role = UserRole.Child
            };
            context.Users.Add(testUser);
        }

        const string admin = "admin";
        var adminUserExist = await context.Users.AnyAsync(u => u.Username == admin);
        if (!adminUserExist)
        {
            var adminUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Admin User",
                Password = BCrypt.Net.BCrypt.HashPassword(admin),
                Username = admin,
                Role = UserRole.Admin
            };
            context.Users.Add(adminUser);
        }

        const string caregiver = "caregiver";
        var caregiverUserExist = await context.Users.AnyAsync(u => u.Username == caregiver);
        if (!caregiverUserExist)
        {
            var caregiverUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Test Caregiver",
                Password = BCrypt.Net.BCrypt.HashPassword(caregiver),
                Username = caregiver,
                Role = UserRole.Caregiver
            };
            context.Users.Add(caregiverUser);
        }

        return context;
    }
}

#pragma warning restore CS1591