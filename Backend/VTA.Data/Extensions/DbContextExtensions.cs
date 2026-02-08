using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Org.BouncyCastle.Crypto.Generators;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.Data.Extensions;

#pragma warning disable CS1591

public static class DbContextExtensions
{
    public static IServiceCollection AddVTAContext(this IServiceCollection services, IConfiguration configuration)
    {
        const string connectionType = "DefaultConnection";

        services.AddDbContext<VTAContext>(opt =>
        {
            try
            {
                opt.UseMySql(
                    configuration.GetConnectionString(connectionType),
                    ServerVersion.AutoDetect(configuration.GetConnectionString(connectionType)),
                    options =>
                    {
                        options.EnableStringComparisonTranslations();
                        options.EnableRetryOnFailure();
                    }
                );
            }
            catch (Exception e)
            {
                // ILogger is not available during DI configuration; use stderr as a last resort.
                Console.Error.WriteLine($"[ERROR] An error occurred while configuring MySQL: {e.Message} — falling back to a volatile DB");
            }
        });
        return services;
    }
}

#pragma warning restore CS1591