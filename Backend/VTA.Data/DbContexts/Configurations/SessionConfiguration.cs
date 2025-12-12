using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

public class SessionConfiguration : IEntityTypeConfiguration<Session>
{
    public void Configure(EntityTypeBuilder<Session> builder)
    {
        builder.HasKey(e => e.Id).HasName("PRIMARY");

        builder.ToTable("sessions");

        builder.Property(e => e.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd();

        builder.Property(e => e.CallerId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("caller_id");

        builder.Property(e => e.CalleeId)
            .IsRequired()
            .HasMaxLength(36)
            .HasColumnName("callee_id");

        builder.Property(e => e.StartTime)
            .HasColumnName("start_time")
            .HasColumnType("datetime");

        builder.Property(e => e.EndTime)
            .HasColumnName("end_time")
            .HasColumnType("datetime");

        builder.Property(e => e.Duration)
            .HasColumnName("duration")
            .HasColumnType("time");

        builder.Property(e => e.CallStatus)
            .IsRequired()
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasColumnName("call_status");

        builder.HasOne(s => s.Caller)
            .WithMany()
            .HasForeignKey(s => s.CallerId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("FK_sessions_caller");

        builder.HasOne(s => s.Callee)
            .WithMany()
            .HasForeignKey(s => s.CalleeId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("FK_sessions_callee");
    }
}
