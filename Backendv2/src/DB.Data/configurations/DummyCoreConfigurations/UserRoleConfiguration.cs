//Made by using scaffolding. Started in DummyCoreContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=DummyCoreConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class UserRoleConfiguration : IEntityTypeConfiguration<UserRole>
{
    public void Configure(EntityTypeBuilder<UserRole> entity)
    {
        entity.HasKey(e => new { e.NonCitizenId, e.OrganizationId, e.Role }).HasName("userRole_pkey");

        entity.ToTable("userRole");

        entity.Property(e => e.NonCitizenId).HasColumnName("nonCitizenId");
        entity.Property(e => e.OrganizationId).HasColumnName("organizationId");
        entity.Property(e => e.Role).HasMaxLength(65).HasColumnName("role");

        entity.HasOne(d => d.NonCitizen).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.NonCitizenId)
                .HasConstraintName("userRole_nonCitizenId_fkey");

        entity.HasOne(d => d.Organization).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.OrganizationId)
                .HasConstraintName("userRole_organizationId_fkey");
}}