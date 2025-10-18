using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class DefaultCategoryConfiguration : IEntityTypeConfiguration<DefaultCategory>
{
    public void Configure(EntityTypeBuilder<DefaultCategory> builder)
    {
        
    }
}