using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class RelationConfiguration : IEntityTypeConfiguration<Relation>
{
    public void Configure(EntityTypeBuilder<Relation> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("relation");

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");
        builder.Property(e => e.CaregiverId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("caregiver_id");
        builder.Property(e => e.ChildId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("child_id");

        builder.Property(e => e.IsActive)
            .HasColumnName("is_active")
            .HasDefaultValueSql("1");

        builder.Property(e => e.CreatedAt)
            .HasColumnType("datetime")
            .HasColumnName("created_at")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.HasOne(d => d.Caregiver)
            .WithMany(p => p.CaregiverRelations)
            .HasForeignKey(d => d.CaregiverId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(d => d.Child)
            .WithMany(p => p.ChildRelations)
            .HasForeignKey(d => d.ChildId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}