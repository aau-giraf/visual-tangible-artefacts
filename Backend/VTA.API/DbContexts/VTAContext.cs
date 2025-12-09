
using Microsoft.EntityFrameworkCore;
using VTA.API.Models;

namespace VTA.API.DbContexts;

public partial class VTAContext : DbContext
{
    public VTAContext()
    {
    }

    public VTAContext(DbContextOptions<VTAContext> options) : base(options)
    {
    }

    public virtual DbSet<Artefact> Artefacts { get; set; }

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<SavedBoard> SavedBoards { get; set; }

    public virtual DbSet<SavedArtefact> SavedArtefacts { get; set; }

   protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    // Category -> User
    modelBuilder.Entity<Category>()
        .HasOne(c => c.User)                // navigation on Category
        .WithMany(u => u.Categories)        // navigation on User
        .HasForeignKey(c => c.UserId)       // FK property
        .OnDelete(DeleteBehavior.Cascade);  // <- ensure EF uses DB cascade

    // Example for SavedBoard -> User (adjust types/names to your model)
    modelBuilder.Entity<SavedBoard>()
        .HasOne(sb => sb.User)
        .WithMany(u => u.SavedBoards)
        .HasForeignKey(sb => sb.UserId)
        .OnDelete(DeleteBehavior.Cascade);

    // SavedArtefact -> SavedBoard (or User) if applicable
    modelBuilder.Entity<SavedArtefact>()
        .HasOne(sa => sa.Board)
        .WithMany(b => b.SavedArtefacts)
        .HasForeignKey(sa => sa.BoardId)
        .OnDelete(DeleteBehavior.Cascade);

    // Repeat for other relations that reference User
}
}

