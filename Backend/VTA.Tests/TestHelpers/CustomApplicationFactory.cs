using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using VTA.API.DbContexts;

namespace VTA.Tests.TestHelpers
{
    public class CustomApplicationFactory<TStartup> : WebApplicationFactory<TStartup> where TStartup : class
    {
        public IConfiguration Configuration { get; private set; }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureAppConfiguration((context, config) =>
            {
                config.AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true, reloadOnChange: true)
                      .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                      .AddEnvironmentVariables();

                Configuration = config.Build();
            });

            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<UserContext>));
                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                var connectionString = Configuration.GetConnectionString("TestConnection") ??
                                       Configuration.GetConnectionString("DefaultConnection");

                services.AddDbContext<UserContext>(options =>
                {
                    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 21)));
                });
            });
        }
    }
}
