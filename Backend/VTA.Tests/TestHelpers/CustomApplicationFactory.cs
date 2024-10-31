using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using VTA.API.DbContexts;

namespace VTA.Tests.TestHelpers
{
    public class CustomApplicationFactory<TStartup> : WebApplicationFactory<TStartup> where TStartup : class
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureAppConfiguration((context, config) =>
            {
                config.AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true, reloadOnChange: true)
                      .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                      .AddEnvironmentVariables();
            });

            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<UserContext>));
                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                var configuration = services.BuildServiceProvider().GetRequiredService<IConfiguration>();
                var connectionString = configuration.GetConnectionString("TestConnection") ??
                                       configuration.GetConnectionString("DefaultConnection");

                services.AddDbContext<UserContext>(options =>
                {
                    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 21)));
                });
            });
        }
    }
}
