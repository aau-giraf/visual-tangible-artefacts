using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class SavedBoardConfiguration : IEntityTypeConfiguration<SavedBoard>
{
    public void Configure(EntityTypeBuilder<SavedBoard> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("savedBoard");

        builder.HasIndex(e => e.UserId, "userId");

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.Name)
            .HasMaxLength(255)
            .HasColumnName("name");

        builder.Property(e => e.UserId)
            .HasMaxLength(36)
            .HasColumnName("userId");

        builder.Property(e => e.SnapshotPath)
            .HasMaxLength(255)
            .HasColumnName("snapshotPath");

        builder.Property(e => e.SavedArtefactIds)
            .HasColumnType("json")
            .HasColumnName("savedArtefactIds");

        builder.Property(e => e.ArtefactIds)
            .HasColumnType("json")
            .HasColumnName("artefactIds");

        builder.Property(e => e.CreatedDate)
            .HasColumnType("datetime")
            .HasColumnName("createdDate")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.Property(e => e.ModifiedDate)
            .HasColumnType("datetime")
            .HasColumnName("modifiedDate");

        // Relationship: SavedBoard -> User (many-to-one)
        builder.HasOne(d => d.User)
            .WithMany(p => p.SavedBoards)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("savedBoard_ibfk_1");

        // Relationship: SavedBoard -> SavedArtefacts collection (one-to-many)
        // This uses the boardId FK in SavedArtefact table
        builder.HasMany(d => d.SavedArtefacts)
            .WithOne(p => p.Board)
            .HasForeignKey(p => p.BoardId)
            .OnDelete(DeleteBehavior.Restrict);

    }
}
