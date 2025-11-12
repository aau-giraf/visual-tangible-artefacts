using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class SavedArtefactConfiguration : IEntityTypeConfiguration<SavedArtefact>
{
    public void Configure(EntityTypeBuilder<SavedArtefact> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("savedArtefact");

        builder.HasIndex(e => e.ArtefactId, "artefactId");

        builder.HasIndex(e => e.BoardId, "boardId");

        // Unique constraint: one artefact per board
        builder.HasIndex(e => new { e.ArtefactId, e.BoardId }, "unique_artefact_board")
            .IsUnique();

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.ArtefactId)
            .HasMaxLength(36)
            .HasColumnName("artefactId");

        builder.Property(e => e.BoardId)
            .HasMaxLength(36)
            .HasColumnName("boardId");

        builder.Property(e => e.PosX)
            .HasColumnName("posX")
            .HasDefaultValue(0f);

        builder.Property(e => e.PosY)
            .HasColumnName("posY")
            .HasDefaultValue(0f);

        builder.Property(e => e.CreatedDate)
            .HasColumnType("datetime")
            .HasColumnName("createdDate")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        // Relationship: SavedArtefact -> Artefact (many-to-one)
        builder.HasOne(d => d.Artefact)
            .WithMany(p => p.SavedArtefacts)
            .HasForeignKey(d => d.ArtefactId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("savedArtefact_ibfk_1");

        // Relationship: SavedArtefact -> SavedBoard (many-to-one)
        // This is configured on the SavedBoard side as well (one-to-many)
        builder.HasOne(d => d.Board)
            .WithMany(p => p.SavedArtefacts)
            .HasForeignKey(d => d.BoardId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("savedArtefact_ibfk_2");
    }
}
