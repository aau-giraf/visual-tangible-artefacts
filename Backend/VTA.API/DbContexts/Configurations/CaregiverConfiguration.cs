using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class CaregiverConfiguration : IEntityTypeConfiguration<Caregiver>
{
    public void Configure(EntityTypeBuilder<Caregiver> builder)
    {
        // Caregiver-specific properties
        builder.Property(e => e.RelationType)
            .HasColumnName("relationType")
            .HasMaxLength(50);

        // Navigation property for caregiver relations
        // Configured in RelationConfiguration with proper foreign keys
    }
}
