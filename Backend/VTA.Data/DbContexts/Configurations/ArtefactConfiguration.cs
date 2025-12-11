using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class ArtefactConfiguration : IEntityTypeConfiguration<Artefact>
{
    public void Configure(EntityTypeBuilder<Artefact> builder)
    {
        builder.HasKey(e => e.ArtefactId).HasName("PRIMARY");

        builder.ToTable("artefact");

        builder.HasIndex(e => e.CategoryId, "categoryId");

        builder.HasIndex(e => e.UserId, "userId");

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
        builder.Property(e => e.UserId)
            .HasMaxLength(36)
            .HasColumnName("userID");
        builder.Property(e => e.Name)
            .HasMaxLength(255)
            .HasColumnName("name");
        builder.Property(e => e.NameShown)
            .HasColumnName("nameShown");

        builder.HasOne(d => d.Category).WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.CategoryId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("artefact_ibfk_2");

        builder.HasOne(d => d.User).WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("artefact_ibfk_1");

        builder.HasMany(d => d.SavedArtefacts).WithOne(p => p.Artefact)
            .HasForeignKey(p => p.ArtefactId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}