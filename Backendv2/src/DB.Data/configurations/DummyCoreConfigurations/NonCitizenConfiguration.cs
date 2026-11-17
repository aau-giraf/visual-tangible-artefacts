//Made by using scaffolding. Started in DummyCoreContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=DummyCoreConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class NonCitizenConfiguration : IEntityTypeConfiguration<NonCitizen>
{
    public void Configure(EntityTypeBuilder<NonCitizen> entity)
    {
        entity.HasKey(e => e.Id).HasName("nonCitizen_pkey");

        entity.ToTable("nonCitizen");

        entity.HasIndex(e => e.Email, "nonCitizen_email_key").IsUnique();

        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
        entity.Property(e => e.Email).HasMaxLength(65).HasColumnName("email");

        entity.HasOne(d => d.IdNavigation).WithOne(p => p.NonCitizen).HasForeignKey<NonCitizen>(d => d.Id).HasConstraintName("nonCitizen_id_fkey");
    }
}