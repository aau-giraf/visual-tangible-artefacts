using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace VTA.API.DbContexts
{
    public class UserContextFactory : IDesignTimeDbContextFactory<UserContext>
    {
        public UserContext CreateDbContext(string[] args)
        {
            // Load configuration from appsettings.json or appsettings.Development.json
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .Build();

            var optionsBuilder = new DbContextOptionsBuilder<UserContext>();
            var connectionString = configuration.GetConnectionString("TestDatabase");

            // Configure MySQL provider
            optionsBuilder.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));

            return new UserContext(optionsBuilder.Options);
        }
    }
}
