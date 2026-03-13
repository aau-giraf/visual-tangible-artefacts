using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class UserSettingsConfiguration : IEntityTypeConfiguration<UserSettings>
{
    public void Configure(EntityTypeBuilder<UserSettings> builder)
    {
        builder.HasKey(e => e.UserId).HasName("PRIMARY");

        builder.ToTable("user_settings");

        builder.Property(e => e.UserId)
            .HasColumnName("user_id")
            .ValueGeneratedNever();

        builder.Property(e => e.NameVisible)
            .HasDefaultValue(false)
            .HasColumnName("name_visible");

        builder.Property(e => e.FieldCount)
            .HasDefaultValue(4)
            .HasColumnName("field_count");
    }
}
