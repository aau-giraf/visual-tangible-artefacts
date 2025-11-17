using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class SessionConfiguration : IEntityTypeConfiguration<Session>
{
    public void Configure(EntityTypeBuilder<Session> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("session");

        builder.HasIndex(e => e.InviteId, "inviteId").IsUnique();
        builder.HasIndex(e => e.RelationId, "relationId");
        builder.HasIndex(e => e.BoardId, "boardId");

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.InviteId)
            .HasColumnName("inviteId");

        builder.Property(e => e.RelationId)
            .HasMaxLength(36)
            .HasColumnName("relationId")
            .IsRequired();

        builder.Property(e => e.BoardId)
            .HasMaxLength(36)
            .HasColumnName("boardId");

        builder.Property(e => e.Status)
            .HasMaxLength(50)
            .HasColumnName("status")
            .IsRequired();

        // Foreign key to Relation (configured in RelationConfiguration)

        // Foreign key to Board (SavedBoard)
        builder.HasOne(s => s.Board)
            .WithMany()
            .HasForeignKey(s => s.BoardId)
            .OnDelete(DeleteBehavior.SetNull)
            .HasConstraintName("session_ibfk_board");

        // Foreign key to Invite (configured in InviteConfiguration)
    }
}
