using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

modelBuilder.Entity<Class>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("class_pkey");

            entity.ToTable("class");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(65)
                .HasColumnName("name");
            entity.Property(e => e.OrganizationId).HasColumnName("organizationId");

            entity.HasOne(d => d.Organization).WithMany(p => p.Classes)
                .HasForeignKey(d => d.OrganizationId)
                .HasConstraintName("class_organizationId_fkey");
        });