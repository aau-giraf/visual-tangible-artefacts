using System;
using System.IO;
using System.Linq;
using System.Text.Json;
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
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true)
                .AddJsonFile("appsettings.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = config.GetValue<string>("ConnectionStrings:TestConnection")
                                   ?? Environment.GetEnvironmentVariable("TEST_CONNECTION_STRING");

            var jwtSecretSection = config.GetSection("Secret").Get<JwtSecretConfig>();
            if (jwtSecretSection == null || string.IsNullOrEmpty(jwtSecretSection.SecretKey))
            {
                var jwtSecretJson = Environment.GetEnvironmentVariable("JWT_SECRET");
                if (string.IsNullOrEmpty(jwtSecretJson))
                {
                    throw new ArgumentNullException("JWT_SECRET environment variable is required for testing.");
                }

                jwtSecretSection = JsonSerializer.Deserialize<JwtSecretConfig>(jwtSecretJson);
            }

            var builder = new MySqlConnectionStringBuilder(connectionString);
            var database = builder.Database;
            var username = builder.UserID;
            var password = builder.Password;

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

            var options = new DbContextOptionsBuilder<UserContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;

            using var context = new UserContext(options);
            await context.Database.EnsureCreatedAsync();
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

            builder.ConfigureAppConfiguration((context, config) =>
            {
                config
                    .AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true)
                    .AddJsonFile("appsettings.json", optional: true)
                    .AddEnvironmentVariables();
            });
        }

        private class JwtSecretConfig
        {
            public string SecretKey { get; set; }
            public string ValidIssuer { get; set; }
            public string ValidAudience { get; set; }
        }
    }
}
