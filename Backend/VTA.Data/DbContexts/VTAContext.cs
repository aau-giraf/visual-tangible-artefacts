using Microsoft.EntityFrameworkCore;
using VTA.Data.Models;

namespace VTA.Data.DbContexts;

//The aplications entity framwork Core database context.
//Provides acess to tables: Artefacts, Categories, Users, SaveBoards, SavedArtefacts, Relations and Sessions.

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

    public virtual DbSet<Relation> Relations { get; set; }

    public virtual DbSet<Session> Sessions { get; set; }

    //Tells entity framwork how to configure the database model, when aplication starts.
    protected override void OnModelCreating(ModelBuilder modelBuilder) =>
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(VTAContext).Assembly);
}