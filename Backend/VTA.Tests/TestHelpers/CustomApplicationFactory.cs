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
using Microsoft.Extensions.Logging;

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

            var jwtSecretConfig = new JwtSecretConfig
            {
                SecretKey = config.GetValue<string>("Secret:SecretKey")
                            ?? Environment.GetEnvironmentVariable("JWT_SECRET"),
                ValidIssuer = "api.vta.com",
                ValidAudience = "user.vta.com"
            };

            if (string.IsNullOrEmpty(jwtSecretConfig.SecretKey))
            {
                throw new ArgumentNullException("A JWT secret is required for token generation.");
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

            var userOptions = new DbContextOptionsBuilder<UserContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;

            using var userContext = new UserContext(userOptions);
            await userContext.Database.EnsureCreatedAsync();

            var categoryOptions = new DbContextOptionsBuilder<CategoryContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;

            using var categoryContext = new CategoryContext(categoryOptions);
            await categoryContext.Database.EnsureCreatedAsync();

            var artefactContextOptions = new DbContextOptionsBuilder<ArtefactContext>()
                .UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString()))
                .Options;
            using var artefactContext = new ArtefactContext(artefactContextOptions);
            await artefactContext.Database.EnsureCreatedAsync();
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

                var descriptor2 = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<CategoryContext>));
                services.Remove(descriptor2);

                var descriptorArtefactContext = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<ArtefactContext>));
                services.Remove(descriptorArtefactContext);

                services.AddDbContext<UserContext>(options =>
                    options.UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())));

                services.AddDbContext<CategoryContext>(options =>
                    options.UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())));

                services.AddDbContext<ArtefactContext>(options =>
                    options.UseMySql(_mySqlContainer.GetConnectionString(), ServerVersion.AutoDetect(_mySqlContainer.GetConnectionString())));
            });

            builder.ConfigureAppConfiguration((context, config) =>
            {
                config
                    .AddJsonFile("/var/www/VTA.API/appsettings.json", optional: true)
                    .AddJsonFile("appsettings.json", optional: true)
                    .AddEnvironmentVariables();
            });

            builder.ConfigureLogging(logging =>
            {
                logging.ClearProviders();
                logging.AddConsole();
                logging.AddDebug();
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
