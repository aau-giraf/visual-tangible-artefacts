//Made by using scaffolding. Started in VTADevContext. Have been mordified some it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Backendv2.DB.Data.Models.VTAModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.VTAConfigurations;

public class LocalImageConfiguration : IEntityTypeConfiguration<LocalImage>
{
    public void Configure(EntityTypeBuilder<LocalImage> entity)
    {
        entity.HasKey(e => e.Id).HasName("local_image_pkey");
        entity.ToTable("local_image");
        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
    }
}