
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

    // Apply all IEntityTypeConfiguration classes from the Configurations folder
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(VTAContext).Assembly);
}
}

