using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.HasKey(e => e.CategoryId).HasName("PRIMARY");

        builder.ToTable("category");

        builder.HasIndex(e => e.UserId, "userId");

        builder.Property(e => e.CategoryId)
            .HasMaxLength(36)
            .HasColumnName("categoryId");
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
        builder.Property(e => e.UserId)
            .HasMaxLength(36)
            .HasColumnName("userId");
        builder.Property(e => e.UsageCount)
            .HasDefaultValue(0)
            .HasColumnName("usageCount");
        builder.Property(e => e.LastUsedDate)
            .HasColumnType("datetime")
            .HasColumnName("lastUsedDate");

        builder.HasOne(d => d.User).WithMany(p => p.Categories)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("category_ibfk_1");
    }
}