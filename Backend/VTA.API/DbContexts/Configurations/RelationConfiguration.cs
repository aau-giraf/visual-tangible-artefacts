using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class RelationConfiguration : IEntityTypeConfiguration<Relation>
{
    public void Configure(EntityTypeBuilder<Relation> builder)
    {
        builder.HasKey(e => e.RelationId).HasName("PRIMARY");

        builder.ToTable("relation");

        builder.HasIndex(e => e.StudentId, "studentId");
        builder.HasIndex(e => e.RelativeId, "relativeId");

        builder.Property(e => e.RelationId)
            .HasMaxLength(36)
            .HasColumnName("relationId");

        builder.Property(e => e.StudentId)
            .HasMaxLength(36)
            .HasColumnName("studentId")
            .IsRequired();

        builder.Property(e => e.RelativeId)
            .HasMaxLength(36)
            .HasColumnName("relativeId")
            .IsRequired();

        builder.Property(e => e.RelationType)
            .HasMaxLength(50)
            .HasColumnName("relationType")
            .IsRequired();

        builder.Property(e => e.Status)
            .HasMaxLength(50)
            .HasColumnName("status")
            .IsRequired();

        builder.Property(e => e.CreatedAt)
            .HasColumnType("datetime")
            .HasColumnName("createdAt")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.Property(e => e.UpdatedAt)
            .HasColumnType("datetime")
            .HasColumnName("updatedAt")
            .HasDefaultValueSql("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");

        // Foreign key relationships with proper navigation properties
        builder.HasOne(r => r.Student)
            .WithMany(c => c.ChildRelations)
            .HasForeignKey(e => e.StudentId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("relation_ibfk_student");

        builder.HasOne(r => r.Relative)
            .WithMany(c => c.CaregiverRelations)
            .HasForeignKey(e => e.RelativeId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("relation_ibfk_relative");

        // One-to-one relationship with Invite
        builder.HasOne(r => r.Invite)
            .WithOne(i => i.Relation)
            .HasForeignKey<Invite>(i => i.RelationId)
            .OnDelete(DeleteBehavior.Cascade);

        // One-to-many relationship with Sessions
        builder.HasMany(r => r.Sessions)
            .WithOne(s => s.Relation)
            .HasForeignKey(s => s.RelationId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
