//Made by using scaffolding. The files in configurations started in here  
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Backendv2.DB.Data;
using Microsoft.EntityFrameworkCore;

namespace Backendv2.DB.Data;

public partial class VtaContext : DbContext
{
    public VtaContext()
    {
    }

    public VtaContext(DbContextOptions<VtaContext> options) : base(options)
    {
    }

    public virtual DbSet<Artefact> Artefacts { get; set; }
    public virtual DbSet<ArtefactBoard> ArtefactBoards { get; set; }
    public virtual DbSet<Board> Boards { get; set; }
    public virtual DbSet<ImageVta> Images { get; set; }
    public virtual DbSet<UserVta> Users { get; set; }
    public virtual DbSet<UserSetting> UserSettings { get; set; }
    public virtual DbSet<LocalImage> LocalImages { get; set; }
    public virtual DbSet<LocalUser> LocalUsers { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
            optionsBuilder.UseNpgsql("Name=VTAConnectionString");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("postgres_fdw");
        modelBuilder.HasSequence<int>("board_id_seq");

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(VtaContext).Assembly);

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}