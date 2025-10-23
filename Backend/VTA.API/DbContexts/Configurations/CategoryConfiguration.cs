using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.ToTable("category");

        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.Property(e => e.Id)
            .HasColumnName("id")
            .HasColumnType("BINARY(16)")
            .HasConversion(Converters.GuidToBytesConverter);

        builder.Property(e => e.CategoryIndex).HasColumnName("categoryIndex");

        builder.Property(e => e.ImagePath)
            .HasMaxLength(255)
            .HasColumnName("imagePath");

        builder.Property(e => e.ModifiedDate)
            .HasColumnType("datetime")
            .HasColumnName("modifiedDate");

        builder.Property(e => e.Name)
            .HasMaxLength(50)
            .HasColumnName("name");

        // TPH discriminator: 0 = DefaultCategory, 1 = UserCategory
        builder.HasDiscriminator<int>("categoryType")
            .HasValue<DefaultCategory>(0)
            .HasValue<UserCategory>(1);
    }
}