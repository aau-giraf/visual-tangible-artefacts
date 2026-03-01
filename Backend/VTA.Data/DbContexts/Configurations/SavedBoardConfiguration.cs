using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

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

        builder.HasMany(d => d.SavedArtefacts)
            .WithOne(p => p.Board)
            .HasForeignKey(p => p.BoardId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
