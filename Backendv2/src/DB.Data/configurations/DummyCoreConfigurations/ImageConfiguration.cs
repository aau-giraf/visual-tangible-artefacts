//Made by using scaffolding. Started in DummyCoreContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=DummyCoreConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class ImageConfiguration : IEntityTypeConfiguration<Image>
{
    public void Configure(EntityTypeBuilder<Image> entity)
    {
        entity.HasKey(e => e.Id).HasName("image_pkey");

        entity.ToTable("image");

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.CitizenId).HasColumnName("citizenId");
        entity.Property(e => e.CreatedAt).HasColumnName("createdAt");
        entity.Property(e => e.FileName).HasMaxLength(255).HasColumnName("fileName");
        entity.Property(e => e.FileType).HasMaxLength(100).HasColumnName("fileType");
        entity.Property(e => e.Name).HasMaxLength(65).HasColumnName("name");
        entity.Property(e => e.OrganizationId).HasColumnName("organizationId");
        entity.Property(e => e.Path).HasMaxLength(65).HasColumnName("path");
        entity.Property(e => e.SizeBytes).HasColumnName("sizeBytes");
        entity.Property(e => e.StorageKey).HasMaxLength(512).HasColumnName("storageKey");

        entity.HasOne(d => d.Citizen).WithMany(p => p.Images).HasForeignKey(d => d.CitizenId).HasConstraintName("image_citizenId_fkey");

        entity.HasOne(d => d.Organization).WithMany(p => p.Images).HasForeignKey(d => d.OrganizationId).HasConstraintName("image_organizationId_fkey");
    }
}