using System;
using System.IO;
using System.Threading.Tasks;
using MySql.Data.MySqlClient;
using Microsoft.EntityFrameworkCore;
using Xunit;
using TestContainers.Container;

// https://dev.to/kashifsoofi/integration-test-mysql-with-testcontainers-dotnet-183b

namespace VTA.Tests.Fixtures
{
    public class DatabaseFixture<TContext> : IAsyncLifetime where TContext : DbContext
    {
        private readonly TestcontainersContainer _container;
        public TContext DbContext { get; private set; }

        public DatabaseFixture()
        {
            _container = new TestcontainersBuilder<TestcontainersContainer>()
                .WithImage("mysql:8.0")
                .WithEnvironment("MYSQL_ROOT_PASSWORD", "password")
                .WithEnvironment("MYSQL_DATABASE", "TestDb")
                .WithPortBinding(3306, true) // Bind to a random host port
                .WithWaitStrategy(Wait.ForUnixContainer().UntilPortIsAvailable(3306))
                .Build();
        }

        public async Task InitializeAsync()
        {
            await _container.StartAsync();

            // Get the mapped port and construct the connection string.
            var mappedPort = _container.GetMappedPublicPort(3306);
            var connectionString = $"Server=localhost;Port={mappedPort};Database=TestDb;Uid=root;Pwd=password;";

            // Load and apply the schema from the production database dump
            var schemaFilePath = TestHelpers.Database.DatabaseSchemaDumper.DumpDatabaseSchema();
            var schemaSql = File.ReadAllText(schemaFilePath);

            using (var connection = new MySqlConnection(connectionString))
            {
                await connection.OpenAsync();
                using (var command = new MySqlCommand(schemaSql, connection))
                {
                    await command.ExecuteNonQueryAsync();
                }
            }

            // Set up DbContext options with the dynamic container connection string.
            var options = new DbContextOptionsBuilder<TContext>()
                .UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 21)))
                .Options;

            DbContext = (TContext) Activator.CreateInstance(typeof(TContext), options);
        }

        public async Task DisposeAsync()
        {
            await _container.StopAsync();
            DbContext?.Dispose();
        }
    }
}
