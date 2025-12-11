using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models;

namespace VTA.API.DbContexts.Configurations;

public class CaregiverChildPairingConfiguration : IEntityTypeConfiguration<CaregiverChildPairing>
{
    public void Configure(EntityTypeBuilder<CaregiverChildPairing> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.CaregiverId)
            .HasMaxLength(36)
            .HasColumnName("caregiverId");

        builder.Property(e => e.ChildId)
            .HasMaxLength(36)
            .HasColumnName("childId");

        builder.Property(e => e.IsActive)
            .HasColumnName("isActive");

        builder.Property(e => e.CreatedAt)
            .HasColumnName("createdAt");

        builder.ToTable("caregiver_child_pairings");
    }
}

public class SessionConfiguration : IEntityTypeConfiguration<Session>
{
    public void Configure(EntityTypeBuilder<Session> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.CaregiverId)
            .HasMaxLength(36)
            .HasColumnName("caregiverId");

        builder.Property(e => e.ChildId)
            .HasMaxLength(36)
            .HasColumnName("childId");

        builder.Property(e => e.State)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasColumnName("state");

        builder.Property(e => e.CreatedAt)
            .HasColumnName("createdAt");

        builder.Property(e => e.StartedAt)
            .HasColumnName("startedAt");

        builder.Property(e => e.EndedAt)
            .HasColumnName("endedAt");

        builder.ToTable("sessions");
    }
}

public class SessionEventConfiguration : IEntityTypeConfiguration<SessionEvent>
{
    public void Configure(EntityTypeBuilder<SessionEvent> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .HasMaxLength(36)
            .HasColumnName("id");

        builder.Property(e => e.SessionId)
            .HasMaxLength(36)
            .HasColumnName("sessionId");

        builder.Property(e => e.EventType)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasColumnName("eventType");

        builder.Property(e => e.Timestamp)
            .HasColumnName("timestamp");

        builder.Property(e => e.Data)
            .HasColumnType("TEXT")
            .HasColumnName("data");

        builder.HasOne(e => e.Session)
            .WithMany(s => s.Events)
            .HasForeignKey(e => e.SessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.ToTable("session_events");
    }
}