using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MySql.Data.MySqlClient;
using Testcontainers.MySql;
using VTA.API.DbContexts;
using Xunit;

namespace VTA.Tests.TestHelpers
{
    public class CustomApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
    {
        private readonly MySqlContainer _mySqlContainer;

        public CustomApplicationFactory()
        {

            var appSettingsPath = "/var/www/VTA.API/appsettings.json";
            var localAppSettingsPath = "appsettings.json";

            // Log for CI/CD output
            Console.WriteLine("Checking if appsettings.json files are accessible...");

            if (File.Exists(appSettingsPath))
            {
                Console.WriteLine($"Found appsettings.json at {appSettingsPath}");
            }
            else
            {
                Console.WriteLine($"Could NOT find appsettings.json at {appSettingsPath}");
            }

            if (File.Exists(localAppSettingsPath))
            {
                Console.WriteLine($"Found appsettings.json at {localAppSettingsPath}");
            }
            else
            {
                Console.WriteLine($"Could NOT find appsettings.json at {localAppSettingsPath}");
            }

            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true)
                .AddJsonFile("appsettings.json", optional: true)
                .Build();

            var testConnectionString = config.GetConnectionString("TestConnection");
            Console.WriteLine($"TestConnectionString: {(string.IsNullOrEmpty(testConnectionString) ? "Not Found" : "Loaded Successfully")}");


            var connectionString = config.GetConnectionString("TestConnection");
            var builder = new MySqlConnectionStringBuilder(connectionString);
            var database = builder.Database;
            var username = builder.UserID;
            var password = builder.Password;

            _mySqlContainer = new MySqlBuilder()
                .WithImage("mysql:8.0")
                .WithDatabase(database)
                .WithUsername(username)
                .WithPassword(password)
                .WithPortBinding(3307, 3306)
                .Build();
        }

        public async Task InitializeAsync()
        {
            await _mySqlContainer.StartAsync();

            var options = new DbContextOptionsBuilder<UserContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;

            using var context = new UserContext(options);
            await context.Database.EnsureCreatedAsync();

            int pauseDuration = 60000;
            Console.WriteLine($"Database schema created. Pausing for {pauseDuration / 1000} seconds to allow inspection...");
            await Task.Delay(pauseDuration);
        }

        public async Task DisposeAsync()
        {
            await _mySqlContainer.DisposeAsync();
        }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<UserContext>));
                services.Remove(descriptor);

                services.AddDbContext<UserContext>(options =>
                    options.UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())));
            });
        }
    }
}
