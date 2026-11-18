//Made by using scaffolding. Started in DummyCoreContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=DummyCoreConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Backendv2.DB.Data.Models.DummyCoreModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class ClassConfiguration : IEntityTypeConfiguration<Class>
{
    public void Configure(EntityTypeBuilder<Class> entity)
    {
        entity.HasKey(e => e.Id).HasName("class_pkey");

        entity.ToTable("class");

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.Name).HasMaxLength(65).HasColumnName("name");
        entity.Property(e => e.OrganizationId).HasColumnName("organizationId");

        entity.HasOne(d => d.Organization).WithMany(p => p.Classes).HasForeignKey(d => d.OrganizationId).HasConstraintName("class_organizationId_fkey");
    }
}