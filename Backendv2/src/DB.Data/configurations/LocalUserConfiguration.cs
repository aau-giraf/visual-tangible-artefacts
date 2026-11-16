using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class LocalUserConfiguration : IEntityTypeConfiguration<LocalUser>
{
    public void Configure(EntityTypeBuilder<LocalUser> entity)
    {
        entity.HasKey(e => e.Id).HasName("local_user_pkey");
        entity.ToTable("local_user");
        entity.Property(e => e.Id).ValueGeneratedNever().HasColumnName("id");
    }
}