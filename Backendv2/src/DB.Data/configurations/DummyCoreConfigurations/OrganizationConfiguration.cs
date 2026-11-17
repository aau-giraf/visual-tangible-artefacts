using Backendv2.ModelsDC;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class OrganizationConfiguration : IEntityTypeConfiguration<Organization>
{
    public void Configure(EntityTypeBuilder<Organization> entity)
    {
        entity.HasKey(e => e.Id).HasName("organization_pkey");

            entity.ToTable("organization");

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.Name)
            .HasMaxLength(65)
            .HasColumnName("name");
    }
}