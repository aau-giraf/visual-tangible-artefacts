//Made by using scaffolding. Started in VTADevContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Backendv2.DB.Data.Models.VTAModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.VTAConfigurations;

public class LocalUserConfiguration : IEntityTypeConfiguration<LocalUser>
{
    public void Configure(EntityTypeBuilder<LocalUser> entity)
    {
        entity.HasKey(e => e.Id).HasName("local_user_pkey");
        entity.ToTable("local_user");
        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
    }
}