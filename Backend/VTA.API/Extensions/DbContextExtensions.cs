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
            await vtaContext.SeedTestData();
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

    private static async Task<VTAContext> SeedTestData(this VTAContext context)
    {
        const string giraf = "giraf";
        
        var testUser = new User
        {
            Id = Guid.NewGuid().ToString(),
            Name = giraf,
            Password = giraf,
            Username = giraf
        };
                
        context.Users.Add(testUser);
        
        await context.SaveChangesAsync();
        
        return context;
    }
}

#pragma warning restore CS1591