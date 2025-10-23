using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts.Configurations;

public class DefaultArtefactConfiguration : IEntityTypeConfiguration<DefaultArtefact>
{
    public void Configure(EntityTypeBuilder<DefaultArtefact> builder)
    {
        builder.HasOne<DefaultCategory>(d => d.Category)
            .WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.CategoryId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("artefact_ibfk_2");
    }
}