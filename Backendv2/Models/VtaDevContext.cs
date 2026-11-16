using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Backendv2.Models;

public partial class VtaDevContext : DbContext
{
    public VtaDevContext()
    {
    }

    public VtaDevContext(DbContextOptions<VtaDevContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Artefact> Artefacts { get; set; }

    public virtual DbSet<ArtefactBoard> ArtefactBoards { get; set; }

    public virtual DbSet<Board> Boards { get; set; }

    public virtual DbSet<Image> Images { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserSetting> UserSettings { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseNpgsql("Name=VTAConnection");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("postgres_fdw");

        modelBuilder.Entity<Artefact>(entity =>
        {
            entity.HasKey(e => e.Imageid).HasName("artefact_pkey");

            entity.ToTable("artefact");

            entity.Property(e => e.Imageid)
                .ValueGeneratedNever()
                .HasColumnName("imageid");
            entity.Property(e => e.UseCount).HasColumnName("useCount");
        });

        modelBuilder.Entity<ArtefactBoard>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("artefact-board");

            entity.Property(e => e.Boardid).HasColumnName("boardid");
            entity.Property(e => e.GridX).HasColumnName("gridX");
            entity.Property(e => e.GridY).HasColumnName("gridY");
            entity.Property(e => e.Imageid).HasColumnName("imageid");
            entity.Property(e => e.PosX).HasColumnName("posX");
            entity.Property(e => e.PosY).HasColumnName("posY");

            entity.HasOne(d => d.Board).WithMany()
                .HasForeignKey(d => d.Boardid)
                .HasConstraintName("artefact-board_boardid_fkey");
        });

        modelBuilder.Entity<Board>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("board_pkey");

            entity.ToTable("board");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.Userid).HasColumnName("userid");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("image");

            entity.Property(e => e.CitizenId).HasColumnName("citizenId");
            entity.Property(e => e.CreatedAt).HasColumnName("createdAt");
            entity.Property(e => e.FileName)
                .HasMaxLength(255)
                .HasColumnName("fileName");
            entity.Property(e => e.FileType)
                .HasMaxLength(100)
                .HasColumnName("fileType");
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.OrganizationId).HasColumnName("organizationId");
            entity.Property(e => e.Path)
                .HasMaxLength(255)
                .HasColumnName("path");
            entity.Property(e => e.SizeBytes).HasColumnName("sizeBytes");
            entity.Property(e => e.StorageKey)
                .HasMaxLength(512)
                .HasColumnName("storageKey");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("user");

            entity.Property(e => e.FirstName)
                .HasMaxLength(255)
                .HasColumnName("firstName");
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.LastName)
                .HasMaxLength(255)
                .HasColumnName("lastName");
            entity.Property(e => e.Password)
                .HasMaxLength(255)
                .HasColumnName("password");
            entity.Property(e => e.Username)
                .HasMaxLength(255)
                .HasColumnName("username");
        });

        modelBuilder.Entity<UserSetting>(entity =>
        {
            entity.HasKey(e => e.Userid).HasName("UserSettings_pkey");

            entity.Property(e => e.Userid)
                .ValueGeneratedNever()
                .HasColumnName("userid");
            entity.Property(e => e.Contrast).HasColumnName("contrast");
            entity.Property(e => e.Darkmode).HasColumnName("darkmode");
            entity.Property(e => e.Language)
                .HasMaxLength(10)
                .HasDefaultValueSql("'dk'::character varying")
                .HasColumnName("language");
            entity.Property(e => e.Lightmode)
                .HasDefaultValue(true)
                .HasColumnName("lightmode");
            entity.Property(e => e.SentenceBar).HasColumnName("sentenceBar");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
