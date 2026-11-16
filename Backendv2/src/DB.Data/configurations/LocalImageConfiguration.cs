using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class LocalImageConfiguration : IEntityTypeConfiguration<LocalImage>
{
    public void Configure(EntityTypeBuilder<LocalImage> entity)
    {
        entity.HasKey(e => e.Id).HasName("local_image_pkey");
        entity.ToTable("local_image");
        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
    }
}