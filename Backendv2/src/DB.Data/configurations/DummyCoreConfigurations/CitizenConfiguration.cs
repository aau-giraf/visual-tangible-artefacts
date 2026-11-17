using Backendv2.ModelsDC;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

public class CitizenConfiguration : IEntityTypeConfiguration<Citizen>
{
    public void Configure(EntityTypeBuilder<Citizen> entity)
    {
        entity.HasKey(e => e.Id).HasName("citizen_pkey");
        entity.ToTable("citizen");
        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
        entity.Property(e => e.ClassId).HasColumnName("classId");

        entity.HasOne(d => d.Class).WithMany(p => p.Citizens).HasForeignKey(d => d.ClassId).HasConstraintName("citizen_classId_fkey");
        entity.HasOne(d => d.IdNavigation).WithOne(p => p.Citizen).HasForeignKey<Citizen>(d => d.Id).HasConstraintName("citizen_id_fkey");

        entity.HasMany(d => d.Guardians).WithMany(p => p.Citizens).UsingEntity<Dictionary<string, object>>

            ("Guardianship",r => r.HasOne<NonCitizen>().WithMany().HasForeignKey("GuardianId").HasConstraintName("guardianship_guardianId_fkey"),

            l => l.HasOne<Citizen>().WithMany().HasForeignKey("CitizenId").HasConstraintName("guardianship_citizenId_fkey"),

            j =>{j.HasKey("CitizenId", "GuardianId").HasName("guardianship_pkey");
                j.ToTable("guardianship");
                j.IndexerProperty<int>("CitizenId").HasColumnName("citizenId");
                j.IndexerProperty<int>("GuardianId").HasColumnName("guardianId");
            });
        }
    }