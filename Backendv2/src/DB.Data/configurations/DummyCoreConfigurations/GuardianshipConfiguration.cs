using Backendv2.DB.Data.Models.DummyCoreModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class GuardianshipConfiguration : IEntityTypeConfiguration<Guardianship>
{
    public void Configure(EntityTypeBuilder<Guardianship> builder)
    {
        builder.ToTable("guardianship");

        builder.HasKey(g => new { g.CitizenId, g.GuardianId });

        builder.Property(g => g.CitizenId).HasColumnName("citizenId");
        builder.Property(g => g.GuardianId).HasColumnName("guardianId");

        builder.HasOne(g => g.Citizen)
            .WithMany(c => c.Guardianships)
            .HasForeignKey(g => g.CitizenId);

        builder.HasOne(g => g.Guardian)
            .WithMany(n => n.Guardianships)
            .HasForeignKey(g => g.GuardianId);
    }
}