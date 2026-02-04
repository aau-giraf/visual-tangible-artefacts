using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MySql.Data.MySqlClient;
using Testcontainers.MySql;
using Microsoft.Extensions.Logging;
using VTA.Data.DbContexts;

namespace VTA.Tests.TestHelpers
{
    public class CustomApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
    {
        private readonly MySqlContainer _mySqlContainer;

        // Static constructor runs once per AppDomain, before any instance is created.
        // This ensures JWT_SECRET is set before WebApplicationFactory starts any host.
        static CustomApplicationFactory()
        {
            // GitHub Actions doesn't expose secrets to fork PRs for security reasons.
            // The workflow sets JWT_SECRET from secrets, but it resolves to empty string.
            if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("JWT_SECRET")))
            {
                Environment.SetEnvironmentVariable("JWT_SECRET", "test-jwt-secret-for-ci-must-be-at-least-32-chars");
            }
        }

        public CustomApplicationFactory()
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("../VTA.API/appsettings.json", optional: true)
                .AddJsonFile("appsettings.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = config.GetValue<string>("ConnectionStrings:TEST_CONNECTION_STRING")
                                   ?? Environment.GetEnvironmentVariable("TEST_CONNECTION_STRING")
                                   ?? "server=localhost;port=3306;user=vta_user;password=vta_password;database=vta_test";

            var builder = new MySqlConnectionStringBuilder(connectionString);
            var database = string.IsNullOrEmpty(builder.Database) ? "vta_test" : builder.Database;
            var username = string.IsNullOrEmpty(builder.UserID) ? "root" : builder.UserID;
            var password = string.IsNullOrEmpty(builder.Password) ? "password" : builder.Password;

            _mySqlContainer = new MySqlBuilder()
                .WithImage("mysql:8.0")
                .WithDatabase(database)
                .WithUsername(username)
                .WithPassword(password)
                .WithExposedPort(3308)
                .Build();
        }

        public async Task InitializeAsync()
        {
            await _mySqlContainer.StartAsync();

            var contextOptions = new DbContextOptionsBuilder<VTAContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;

            await using var vtaContext = new VTAContext(contextOptions);
            await vtaContext.Database.EnsureCreatedAsync();
        }

        public override async ValueTask DisposeAsync()
        {
            await _mySqlContainer.DisposeAsync();
            await base.DisposeAsync();
        }

        async Task IAsyncLifetime.DisposeAsync()
        {
            await DisposeAsync();
        }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<VTAContext>));
                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                services.AddDbContext<VTAContext>(options =>
                    options.UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())));
            });

            builder.ConfigureAppConfiguration((context, config) =>
            {
                config
                    .AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true)
                    .AddJsonFile("appsettings.json", optional: true)
                    .AddEnvironmentVariables()
                    .AddInMemoryCollection(new Dictionary<string, string?>
                    {
                        ["Secret:SecretKey"] = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")
                                               ?? "test-jwt-secret-for-ci-must-be-at-least-32-chars"
                    });
            });

            builder.ConfigureLogging(logging =>
            {
                logging.ClearProviders();
                logging.AddConsole();
                logging.AddDebug();
            });
        }

    }
}