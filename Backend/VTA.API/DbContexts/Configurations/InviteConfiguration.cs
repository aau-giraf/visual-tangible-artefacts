using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class InviteConfiguration : IEntityTypeConfiguration<Invite>
{
    public void Configure(EntityTypeBuilder<Invite> builder)
    {
        builder.HasKey(e => e.InviteId).HasName("PRIMARY");

        builder.ToTable("invite");

        builder.HasIndex(e => e.CreatedBy, "createdBy");
        builder.HasIndex(e => e.RelationId, "relationId");

        builder.Property(e => e.InviteId)
            .ValueGeneratedOnAdd()
            .HasColumnName("inviteId");

        builder.Property(e => e.CreatedAt)
            .HasColumnType("datetime")
            .HasColumnName("createdAt")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.Property(e => e.ExpiresAt)
            .HasColumnType("datetime")
            .HasColumnName("expiresAt")
            .IsRequired();

        builder.Property(e => e.CreatedBy)
            .HasMaxLength(36)
            .HasColumnName("createdBy")
            .IsRequired();

        builder.Property(e => e.RelationId)
            .HasMaxLength(36)
            .HasColumnName("relationId")
            .IsRequired();

        builder.Property(e => e.InviteStatus)
            .HasMaxLength(50)
            .HasColumnName("status")
            .IsRequired();

        // Foreign key to User (CreatedBy)
        builder.HasOne(i => i.Creator)
            .WithMany()
            .HasForeignKey(e => e.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("invite_ibfk_user");

        // Foreign key to Relation (configured in RelationConfiguration)
        // One-to-one relationship with Session
        builder.HasOne(i => i.Session)
            .WithOne(s => s.Invite)
            .HasForeignKey<Session>(s => s.InviteId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
