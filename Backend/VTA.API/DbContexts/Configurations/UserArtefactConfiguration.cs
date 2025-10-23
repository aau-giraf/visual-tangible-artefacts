using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts.Configurations;

public class UserArtefactConfiguration : IEntityTypeConfiguration<UserArtefact>
{
    public void Configure(EntityTypeBuilder<UserArtefact> builder)
    {
        builder.HasIndex(e => e.UserId, "userId");

        builder.Property(e => e.UserId)
            .HasColumnName("userId")
            .HasColumnType("BINARY(16)")
            .HasConversion(Converters.GuidToBytesConverter);

        // Relationship with UserCategory
        builder.HasOne<UserCategory>(d => d.Category)
            .WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.CategoryId)
            .OnDelete(DeleteBehavior.Restrict)
            .HasConstraintName("artefact_ibfk_2");

        // Relationship with User
        builder.HasOne(d => d.User)
            .WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.ClientSetNull)
            .HasConstraintName("artefact_ibfk_1");
    }
}