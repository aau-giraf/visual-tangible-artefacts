using VTA.Data.DbContexts;

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
            var vtaContext = scope.ServiceProvider.GetRequiredService<VTAContext>();
            await vtaContext.Database.EnsureCreatedAsync();
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
}
