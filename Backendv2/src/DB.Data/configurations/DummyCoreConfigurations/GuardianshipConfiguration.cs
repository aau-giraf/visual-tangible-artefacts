using Backendv2.DB.Data.Models.DummyCoreModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class GuardianshipConfiguration : IEntityTypeConfiguration<Guardianship>
{
    public void Configure(EntityTypeBuilder<Guardianship> builder)
    {
        builder.ToTable("guardianship");

        builder.HasKey(g => new { g.CitizenId, g.GuardianId })
            .HasName("guardianship_pkey");

        builder.Property(g => g.CitizenId).HasColumnName("citizenId");
        builder.Property(g => g.GuardianId).HasColumnName("guardianId");

        builder.HasOne(g => g.Citizen)
            .WithMany(c => c.Guardianships)
            .HasForeignKey(g => g.CitizenId)
            .HasConstraintName("guardianship_citizenId_fkey");

        builder.HasOne(g => g.Guardian)
            .WithMany(n => n.Guardianships)
            .HasForeignKey(g => g.GuardianId)
            .HasConstraintName("guardianship_guardianId_fkey");
    }
}