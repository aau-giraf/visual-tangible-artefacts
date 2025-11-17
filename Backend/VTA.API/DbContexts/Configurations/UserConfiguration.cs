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

        // Configure TPH (Table-Per-Hierarchy) inheritance
        builder.HasDiscriminator<string>("UserType")
            .HasValue<User>("User")
            .HasValue<Caregiver>("Caregiver")
            .HasValue<Admin>("Admin")
            .HasValue<Child>("Child");

        builder.Property(e => e.GuardianKey)
            .HasMaxLength(255)
            .HasColumnName("guardianKey");
            
        builder.Property(e => e.Name)
            .HasMaxLength(50)
            .HasColumnName("name");

        builder.Property(e => e.Username)
            .HasMaxLength(50)
            .HasColumnName("username");
            
        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.Password)
            .HasMaxLength(255)
            .HasColumnName("password")
            .IsRequired();

        builder.Property(e => e.FirstName)
            .HasMaxLength(100)
            .HasColumnName("firstName");

        builder.Property(e => e.LastName)
            .HasMaxLength(100)
            .HasColumnName("lastName");

        // Role is configured as a string/enum
        builder.Property(e => e.Role)
            .HasMaxLength(50)
            .HasColumnName("role")
            .IsRequired();

    }
}