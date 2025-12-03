using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class SessionConfiguration : IEntityTypeConfiguration<Session>
{
    public void Configure(EntityTypeBuilder<Session> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("sessions");

        builder.Property(e => e.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd();

        builder.Property(e => e.CaregiverId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("caregiver_id");

        builder.Property(e => e.ChildId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("child_id");

        builder.Property(e => e.CallStatus)
            .IsRequired()
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasColumnName("call_status");

        builder.HasOne(s => s.Caregiver)
            .WithMany()
            .HasForeignKey(s => s.CaregiverId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("FK_sessions_caregiver");

        builder.HasOne(s => s.Child)
            .WithMany()
            .HasForeignKey(s => s.ChildId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("FK_sessions_child");
    }
}
