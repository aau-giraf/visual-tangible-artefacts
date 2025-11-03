
using Microsoft.EntityFrameworkCore;
using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;
using VTA.API.Models.Users;

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

    protected override void OnModelCreating(ModelBuilder modelBuilder) =>
        modelBuilder
            .UseCollation("utf8mb4_0900_ai_ci")
            .HasCharSet("utf8mb4")
            .ApplyConfigurationsFromAssembly(typeof(VTAContext).Assembly);
}
