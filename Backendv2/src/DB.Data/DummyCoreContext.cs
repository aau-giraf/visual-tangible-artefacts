using Microsoft.EntityFrameworkCore;

namespace Backendv2.DB.Data.Models.DummyCoreModels;

public partial class DummyCoreContext : DbContext
{
    public DummyCoreContext()
    {
    }

    public DummyCoreContext(DbContextOptions<DummyCoreContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Citizen> Citizens { get; set; }
    public virtual DbSet<Class> Classes { get; set; }
    public virtual DbSet<Image> Images { get; set; }
    public virtual DbSet<NonCitizen> NonCitizens { get; set; }
    public virtual DbSet<Organization> Organizations { get; set; }
    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<UserRole> UserRoles { get; set; }
    public virtual DbSet<Guardianship> Guardianships { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
            optionsBuilder.UseNpgsql("Name=DummyCoreConnectionString");
    }
        

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        
        modelBuilder.HasSequence<int>("class_id_seq");
        modelBuilder.HasSequence<int>("image_id_seq");
        modelBuilder.HasSequence<int>("organization_id_seq");
        modelBuilder.HasSequence<int>("user_id_seq");

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DummyCoreContext).Assembly, t => t.Namespace == "Backendv2.DB.Data.Configurations.DummyCoreConfigurations");

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
