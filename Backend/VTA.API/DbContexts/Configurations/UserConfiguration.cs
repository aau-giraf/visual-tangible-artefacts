using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("user");

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");
        builder.Property(e => e.GuardianKey)
            .HasMaxLength(255)
            .HasColumnName("guardianKey");
        builder.Property(e => e.Name)
            .HasMaxLength(50)
            .HasColumnName("name");
        builder.Property(e => e.Password)
            .HasMaxLength(255)
            .HasColumnName("password");
        builder.Property(e => e.Username)
            .HasMaxLength(50)
            .HasColumnName("username");
    }
}