using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MySql.Data.MySqlClient;
using Testcontainers.MySql;
using VTA.API.DbContexts;

namespace VTA.Tests.TestHelpers
{
    /// <summary>
    /// Custom application factory for integration tests.
    /// Spins up a MySQL test container and configures the application for testing.
    /// </summary>
    public class CustomApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
    {
        private readonly MySqlContainer _mySqlContainer;

        public CustomApplicationFactory()
        {
            // Load test configuration
            var config = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
                .AddEnvironmentVariables()
                .Build();

            // Get and validate connection string
            var connectionString = config.GetValue<string>("ConnectionStrings:TestConnection")
                ?? throw new InvalidOperationException("TestConnection string is required in appsettings.json");

            // Parse connection string
            var builder = new MySqlConnectionStringBuilder(connectionString);
            var database = builder.Database ?? throw new InvalidOperationException("Database name is required");
            var username = builder.UserID ?? throw new InvalidOperationException("User ID is required");
            var password = builder.Password ?? throw new InvalidOperationException("Password is required");

            // Validate JWT secret exists
            var jwtSecret = config.GetValue<string>("Secret:SecretKey")
                ?? throw new InvalidOperationException("Secret:SecretKey is required in appsettings.json");

            // Create MySQL test container
            _mySqlContainer = new MySqlBuilder()
                .WithImage("mysql:8.0")
                .WithDatabase(database)
                .WithUsername(username)
                .WithPassword(password)
                .Build();
        }

        public async Task InitializeAsync()
        {
            // Start the MySQL container
            await _mySqlContainer.StartAsync();

            // Create the database schema
            var contextOptions = new DbContextOptionsBuilder<VTAContext>()
                .UseMySql(
                    _mySqlContainer.GetConnectionString(),
                    ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())
                )
                .Options;

            await using var vtaContext = new VTAContext(contextOptions);
            await vtaContext.Database.EnsureCreatedAsync();
        }

        public new async Task DisposeAsync()
        {
            await _mySqlContainer.DisposeAsync();
            await base.DisposeAsync();
        }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseContentRoot(Directory.GetCurrentDirectory());

            builder.ConfigureAppConfiguration((context, config) =>
            {
                // Clear all default configurations
                config.Sources.Clear();

                // Add test appsettings.json from VTA.Tests project directory
                config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
                      .AddEnvironmentVariables();
            });

            builder.ConfigureServices(services =>
            {
                // Remove the application's DbContext registration
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<VTAContext>));
                
                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                // Add DbContext with test container connection string
                services.AddDbContext<VTAContext>(options =>
                {
                    options.UseMySql(
                        _mySqlContainer.GetConnectionString(),
                        ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()),
                        mySqlOptions => mySqlOptions.EnableRetryOnFailure()
                    );
                });
            });

            builder.ConfigureLogging(logging =>
            {
                logging.ClearProviders();
                logging.AddConsole();
                logging.SetMinimumLevel(LogLevel.Warning);
            });
        }
    }
}