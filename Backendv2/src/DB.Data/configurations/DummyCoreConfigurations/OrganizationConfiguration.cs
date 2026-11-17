using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

 modelBuilder.Entity<Organization>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("organization_pkey");

            entity.ToTable("organization");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(65)
                .HasColumnName("name");
        });
