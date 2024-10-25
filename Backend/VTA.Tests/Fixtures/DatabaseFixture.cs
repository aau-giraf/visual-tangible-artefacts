using System;
using System.IO;
using System.Threading.Tasks;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using MySql.Data.MySqlClient;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace VTA.Tests.Fixtures
{
    public class DatabaseFixture<TContext> : IAsyncLifetime where TContext : DbContext
    {
        private readonly MySqlTestcontainer _container;
        public TContext DbContext { get; private set; }

        public DatabaseFixture()
        {
            _container = new TestcontainersBuilder<MySqlTestcontainer>()
                .WithImage("mysql:8.0")
                .WithEnvironment("MYSQL_ROOT_PASSWORD", "password")
                .WithEnvironment("MYSQL_DATABASE", "TestDb")
                .Build();
        }

        public async Task InitializeAsync()
        {
            await _container.StartAsync();

            var schemaFilePath = TestHelpers.Database.DatabaseSchemaDumper.DumpDatabaseSchema();
            var schemaSql = File.ReadAllText(schemaFilePath);

            using (var connection = new MySqlConnection(_container.ConnectionString))
            {
                await connection.OpenAsync();
                using (var command = new MySqlCommand(schemaSql, connection))
                {
                    await command.ExecuteNonQueryAsync();
                }
            }

            var options = new DbContextOptionsBuilder<TContext>()
                .UseMySql(_container.ConnectionString, new MySqlServerVersion(new Version(8, 0, 21)))
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
