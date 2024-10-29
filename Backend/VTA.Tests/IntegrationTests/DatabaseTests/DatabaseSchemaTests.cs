using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.Tests.Fixtures;
using Xunit;

namespace VTA.Tests.IntegrationTests
{
    public class DatabaseSchemaTests : IClassFixture<DatabaseFixture<ArtefactContext>>
    {
        private readonly ArtefactContext _dbContext;

        public DatabaseSchemaTests(DatabaseFixture<ArtefactContext> fixture)
        {
            _dbContext = fixture.DbContext;
        }

        [Fact]
        public async Task Database_HasCorrectSchema()
        {
            var tableExists = await _dbContext.Database.ExecuteSqlRawAsync(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Artefacts';");

            Assert.Equal(1, tableExists); // Assert that the 'Artefacts' table exists

            // Check if a specific column exists in the 'Artefacts' table
            var columnExists = await _dbContext.Database.ExecuteSqlRawAsync(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Artefacts' AND COLUMN_NAME = 'ArtefactId';");

            Assert.Equal(1, columnExists); // Assert that the 'ArtefactId' column exists
        }
    }
}
