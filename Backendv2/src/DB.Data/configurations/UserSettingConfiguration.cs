using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class UserSettingConfiguration : IEntityTypeConfiguration<UserSetting>
{
    public void Configure(EntityTypeBuilder<UserSetting> entity)
    {
        entity.HasKey(e => e.UserId); // scaffold says keyless, see note below
        entity.ToTable("userSettings");

        entity.Property(e => e.UserId).ValueGeneratedNever().HasColumnName("userId");
        entity.Property(e => e.Contrast).HasColumnName("contrast");
        entity.Property(e => e.Darkmode).HasColumnName("darkmode");
        entity.Property(e => e.Language).HasMaxLength(10)
            .HasDefaultValueSql("'dk'::character varying").HasColumnName("language");
        entity.Property(e => e.Lightmode).HasDefaultValue(true).HasColumnName("lightmode");
        entity.Property(e => e.SentenceBar).HasColumnName("sentenceBar");

        entity.HasOne(d => d.User).WithMany()
            .HasForeignKey(d => d.UserId)
            .HasConstraintName("userSettings_userId_fkey");
    }
}