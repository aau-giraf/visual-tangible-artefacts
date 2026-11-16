using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class ArtefactConfiguration : IEntityTypeConfiguration<Artefact>
{
	public void Configure(EntityTypeBuilder<Artefact> entity)
	{
		entity.HasKey(e => e.ImageId); // scaffold says keyless, see note below
		entity.ToTable("artefact");

		entity.Property(e => e.ImageId).ValueGeneratedNever().HasColumnName("imageId");
		entity.Property(e => e.UseCount).HasColumnName("useCount");

		entity.HasOne(d => d.Image).WithMany()
			.HasForeignKey(d => d.ImageId)
			.HasConstraintName("artefact_imageId_fkey");
	}
}