using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Artefacts;

namespace VTA.API.DbContexts.Configurations;

public class ArtefactConfiguration : IEntityTypeConfiguration<Artefact>
{
    public void Configure(EntityTypeBuilder<Artefact> builder)
    {
        builder.ToTable("artefact");

        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.HasIndex(e => e.CategoryId, "categoryId");

        builder.Property(e => e.Id)
            .HasColumnName("id")
            .HasColumnType("BINARY(16)")
            .HasConversion(Converters.GuidToBytesConverter);

        builder.Property(e => e.ArtefactIndex).HasColumnName("artefactIndex");

        builder.Property(e => e.CategoryId)
            .HasColumnName("categoryId")
            .HasColumnType("BINARY(16)")
            .HasConversion(Converters.GuidToBytesConverter);

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

        builder.HasDiscriminator<int>("artefactType")
            .HasValue<DefaultArtefact>(0)
            .HasValue<UserArtefact>(1);
    }
}