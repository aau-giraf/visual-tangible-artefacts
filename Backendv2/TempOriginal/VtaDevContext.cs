using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Backendv2.TempOriginal;

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

    public virtual DbSet<LocalImage> LocalImages { get; set; }

    public virtual DbSet<LocalUser> LocalUsers { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserSetting> UserSettings { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseNpgsql("Name=VTAConnectionString");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("postgres_fdw");

        modelBuilder.Entity<Artefact>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("artefact");

            entity.Property(e => e.ImageId).HasColumnName("imageId");
            entity.Property(e => e.UseCount).HasColumnName("useCount");

            entity.HasOne(d => d.Image).WithMany()
                .HasForeignKey(d => d.ImageId)
                .HasConstraintName("artefact_imageId_fkey");
        });

        modelBuilder.Entity<ArtefactBoard>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("artefact-board");

            entity.Property(e => e.BoardId).HasColumnName("boardId");
            entity.Property(e => e.GridX).HasColumnName("gridX");
            entity.Property(e => e.GridY).HasColumnName("gridY");
            entity.Property(e => e.ImageId).HasColumnName("imageId");
            entity.Property(e => e.PosX).HasColumnName("posX");
            entity.Property(e => e.PosY).HasColumnName("posY");

            entity.HasOne(d => d.Board).WithMany()
                .HasForeignKey(d => d.BoardId)
                .HasConstraintName("artefact-board_boardId_fkey");

            entity.HasOne(d => d.Image).WithMany()
                .HasForeignKey(d => d.ImageId)
                .HasConstraintName("artefact-board_imageId_fkey");
        });

        modelBuilder.Entity<Board>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("board_pkey");

            entity.ToTable("board");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.UserId).HasColumnName("userId");

            entity.HasOne(d => d.User).WithMany(p => p.Boards)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("board_userId_fkey");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("image");

            entity.Property(e => e.Id).HasColumnName("id");
        });

        modelBuilder.Entity<LocalImage>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("local_image_pkey");

            entity.ToTable("local_image");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
        });

        modelBuilder.Entity<LocalUser>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("local_user_pkey");

            entity.ToTable("local_user");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("user");

            entity.Property(e => e.Id).HasColumnName("id");
        });

        modelBuilder.Entity<UserSetting>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("userSettings");

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
            entity.Property(e => e.UserId).HasColumnName("userId");

            entity.HasOne(d => d.User).WithMany()
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("userSettings_userId_fkey");
        });
        modelBuilder.HasSequence<int>("board_id_seq");

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
