using Microsoft.EntityFrameworkCore;
using Testcontainers.PostgreSql;
using VTA.Data.DbContexts;

namespace SyncService.Tests.Helpers
{
    /// <summary>
    /// Database fixture that manages a PostgreSQL Testcontainer for integration tests
    /// Shared across all tests in the collection to avoid starting/stopping container per test
    /// </summary>
    public class DatabaseFixture : IAsyncLifetime
    {
        private PostgreSqlContainer? _container;
        public VTAContext DbContext { get; private set; } = null!;

        public async Task InitializeAsync()
        {
            _container = new PostgreSqlBuilder()
                .WithImage("postgresql:8.0")
                .WithDatabase("vta_test")
                .WithUsername("root")
                .WithPassword("test_password")
                .Build();

            await _container.StartAsync();

            var connectionString = _container.GetConnectionString();
            var options = new DbContextOptionsBuilder<VTAContext>()
                .UsePostgreSql(connectionString, ServerVersion.AutoDetect(connectionString))
                .Options;
            
            DbContext = new VTAContext(options);
            await DbContext.Database.EnsureCreatedAsync();
        }

        public async Task DisposeAsync()
        {
            await DbContext.Database.EnsureDeletedAsync();
            await DbContext.DisposeAsync();

            if (_container != null)
            {
                await _container.StopAsync();
                await _container.DisposeAsync();
            }
        }
    }

    /// <summary>
    /// Collection fixture definition - tells XUnit to share DatabaseFixture across all tests in BoardHubTestsCollection
    /// </summary>
    [CollectionDefinition("BoardHub Database Collection")]
    public class DatabaseCollection : ICollectionFixture<DatabaseFixture>
    {
        // This class has no code, it's just used to define the collection
    }
}

