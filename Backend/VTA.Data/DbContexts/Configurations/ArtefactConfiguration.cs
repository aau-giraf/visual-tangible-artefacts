using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using VTA.Data.Models;

namespace VTA.Data.DbContexts.Configurations;

//Tells Entity Framework Core how the Artefact class should be represented in the database.
public class ArtefactConfiguration : IEntityTypeConfiguration<Artefact>
{
    public void Configure(EntityTypeBuilder<Artefact> builder)
    {
        //ArtefactId is primary key and database table is named Artefact.
        builder.HasKey(e => e.ArtefactId).HasName("PRIMARY");

        builder.ToTable("artefact");

        //Database indexes
        builder.HasIndex(e => e.CategoryId, "categoryId");

        builder.HasIndex(e => e.UserId, "userId");

        //Maps ArtefactId to column with name atefactId and can contain at most 36 charecters.
        builder.Property(e => e.ArtefactId)
            .HasMaxLength(36)
            .HasColumnName("artefactId");
        builder.Property(e => e.ArtefactIndex).HasColumnName("artefactIndex");
        builder.Property(e => e.CategoryId)
            .HasMaxLength(36)
            .HasColumnName("categoryId");
        builder.Property(e => e.ImagePath)
            .HasMaxLength(255)
            .HasColumnName("imagePath");
        builder.Property(e => e.SoundPath)
            .HasMaxLength(255)
            .HasColumnName("soundPath");
        builder.Property(e => e.ModifiedDate)
            .HasColumnType("datetime")
            .HasColumnName("modifiedDate");
        builder.Property(e => e.UserId)
            .HasMaxLength(36)
            .HasColumnName("userID");
        builder.Property(e => e.Name)
            .HasMaxLength(255)
            .HasColumnName("name");
        builder.Property(e => e.NameShown)
            .HasColumnName("nameShown");

        //Bottom section defines how artefact relates to other entities
        builder.HasOne(d => d.Category).WithMany(p => p.Artefacts) //One category can have many artefacts.
            .HasForeignKey(d => d.CategoryId)
            .OnDelete(DeleteBehavior.Restrict) //Restrict means you cant delete a category while an artefact stil reference it.
            .HasConstraintName("artefact_ibfk_2"); 

        builder.HasOne(d => d.User).WithMany(p => p.Artefacts)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade) //If user is deleted, their artefacts are automatically seleted too.
            .HasConstraintName("artefact_ibfk_1");

        builder.HasMany(d => d.SavedArtefacts).WithOne(p => p.Artefact)
            .HasForeignKey(p => p.ArtefactId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}