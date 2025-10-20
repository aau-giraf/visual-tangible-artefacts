using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Artefacts;

namespace VTA.API.DbContexts.Configurations;

public class ArtefactConfiguration : IEntityTypeConfiguration<Artefact>
{
    public void Configure(EntityTypeBuilder<Artefact> builder)
    {
        builder.ToTable("artefact");

        builder.HasKey(e => e.ArtefactId).HasName("PRIMARY");

        builder.HasIndex(e => e.CategoryId, "categoryId");

        builder.Property(e => e.ArtefactId)
            .HasMaxLength(36)
            .HasColumnName("artefactId");

        builder.Property(e => e.ArtefactIndex).HasColumnName("artefactIndex");

        builder.Property(e => e.CategoryId)
            .HasMaxLength(36)
            .HasColumnName("categoryId");

        builder.Property(e => e.ImagePath)
            .HasMaxLength(255)
            .HasColumnName("imagePath");

        builder.Property(e => e.SoundPath)
            .HasMaxLength(255)
            .HasColumnName("soundPath");

        builder.Property(e => e.ModifiedDate)
            .HasColumnType("datetime")
            .HasColumnName("modifiedDate");

        builder.Property(e => e.Name)
            .HasMaxLength(255)
            .HasColumnName("name");

        // TPH discriminator: 0 = DefaultArtefact, 1 = UserArtefact
        builder.HasDiscriminator<int>("artefactType")
            .HasValue<DefaultArtefact>(0)
            .HasValue<UserArtefact>(1);

        // Note: Relationships are configured in derived type configurations
    }
}