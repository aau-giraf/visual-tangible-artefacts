using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts.Configurations;

public class UserCategoryConfiguration : IEntityTypeConfiguration<UserCategory>
{
    public void Configure(EntityTypeBuilder<UserCategory> builder)
    {
        builder.HasIndex(e => e.UserId, "userId");

        builder.Property(e => e.UserId)
            .HasColumnName("userId")
            .HasColumnType("BINARY(16)")
            .HasConversion(Converters.GuidToBytesConverter);

        builder.Property(e => e.UsageCount)
            .HasDefaultValue(0)
            .HasColumnName("usageCount");

        builder.Property(e => e.LastUsedDate)
            .HasColumnType("datetime")
            .HasColumnName("lastUsedDate");

        builder.HasOne(d => d.User)
            .WithMany(p => p.Categories)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.ClientSetNull)
            .HasConstraintName("category_ibfk_1");
    }
}