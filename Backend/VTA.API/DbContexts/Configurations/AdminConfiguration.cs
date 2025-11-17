using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class AdminConfiguration : IEntityTypeConfiguration<Admin>
{
    public void Configure(EntityTypeBuilder<Admin> builder)
    {
        // Admin has no additional properties beyond the base User class
        // Configuration is primarily handled in UserConfiguration with TPH discriminator
    }
}
