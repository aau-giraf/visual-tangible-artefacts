using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts.Configurations;

public class DefaultCategoryConfiguration : IEntityTypeConfiguration<DefaultCategory>
{
    public void Configure(EntityTypeBuilder<DefaultCategory> builder)
    {
        // No additional configuration needed for DefaultCategory
        // Relationships are defined in DefaultArtefactConfiguration
    }
}