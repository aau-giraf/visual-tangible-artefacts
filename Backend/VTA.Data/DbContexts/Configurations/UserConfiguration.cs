using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("user");

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");
        builder.Property(e => e.Role)
            .IsRequired()
            .HasColumnName("role");
        builder.Property(e => e.Name)
            .HasMaxLength(50)
            .HasColumnName("name");
        builder.Property(e => e.Password)
            .HasMaxLength(255)
            .HasColumnName("password");
        builder.Property(e => e.Username)
            .HasMaxLength(50)
            .HasColumnName("username");
        builder.Property(e => e.NameVisible)
            .HasColumnName("nameVisible")
            .HasDefaultValue(false);
        builder.Property(e => e.FieldCount)
            .HasColumnName("fieldCount")
            .HasDefaultValue(4);

        builder.Property(e => e.Role)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasColumnName("role")
            .HasDefaultValue(UserRole.Child);

        builder.HasMany(u => u.CaregiverRelations)
            .WithOne(p => p.Caregiver)
            .HasForeignKey(p => p.CaregiverId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(u => u.ChildRelations)
            .WithOne(p => p.Child)
            .HasForeignKey(p => p.ChildId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}