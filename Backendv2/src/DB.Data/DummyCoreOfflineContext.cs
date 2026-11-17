using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Backendv2.ModelsDC;

public partial class DummyCoreOfflineContext : DbContext
{
    public DummyCoreOfflineContext()
    {
    }

    public DummyCoreOfflineContext(DbContextOptions<DummyCoreOfflineContext> options)
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

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseNpgsql("Name=DummyCoreConnectionString");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Citizen>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("citizen_pkey");

            entity.ToTable("citizen");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.ClassId).HasColumnName("classId");

            entity.HasOne(d => d.Class).WithMany(p => p.Citizens)
                .HasForeignKey(d => d.ClassId)
                .HasConstraintName("citizen_classId_fkey");

            entity.HasOne(d => d.IdNavigation).WithOne(p => p.Citizen)
                .HasForeignKey<Citizen>(d => d.Id)
                .HasConstraintName("citizen_id_fkey");

            entity.HasMany(d => d.Guardians).WithMany(p => p.Citizens)
                .UsingEntity<Dictionary<string, object>>(
                    "Guardianship",
                    r => r.HasOne<NonCitizen>().WithMany()
                        .HasForeignKey("GuardianId")
                        .HasConstraintName("guardianship_guardianId_fkey"),
                    l => l.HasOne<Citizen>().WithMany()
                        .HasForeignKey("CitizenId")
                        .HasConstraintName("guardianship_citizenId_fkey"),
                    j =>
                    {
                        j.HasKey("CitizenId", "GuardianId").HasName("guardianship_pkey");
                        j.ToTable("guardianship");
                        j.IndexerProperty<int>("CitizenId").HasColumnName("citizenId");
                        j.IndexerProperty<int>("GuardianId").HasColumnName("guardianId");
                    });
        });

        modelBuilder.Entity<Class>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("class_pkey");

            entity.ToTable("class");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(65)
                .HasColumnName("name");
            entity.Property(e => e.OrganizationId).HasColumnName("organizationId");

            entity.HasOne(d => d.Organization).WithMany(p => p.Classes)
                .HasForeignKey(d => d.OrganizationId)
                .HasConstraintName("class_organizationId_fkey");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("image_pkey");

            entity.ToTable("image");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CitizenId).HasColumnName("citizenId");
            entity.Property(e => e.CreatedAt).HasColumnName("createdAt");
            entity.Property(e => e.FileName)
                .HasMaxLength(255)
                .HasColumnName("fileName");
            entity.Property(e => e.FileType)
                .HasMaxLength(100)
                .HasColumnName("fileType");
            entity.Property(e => e.Name)
                .HasMaxLength(65)
                .HasColumnName("name");
            entity.Property(e => e.OrganizationId).HasColumnName("organizationId");
            entity.Property(e => e.Path)
                .HasMaxLength(65)
                .HasColumnName("path");
            entity.Property(e => e.SizeBytes).HasColumnName("sizeBytes");
            entity.Property(e => e.StorageKey)
                .HasMaxLength(512)
                .HasColumnName("storageKey");

            entity.HasOne(d => d.Citizen).WithMany(p => p.Images)
                .HasForeignKey(d => d.CitizenId)
                .HasConstraintName("image_citizenId_fkey");

            entity.HasOne(d => d.Organization).WithMany(p => p.Images)
                .HasForeignKey(d => d.OrganizationId)
                .HasConstraintName("image_organizationId_fkey");
        });

        modelBuilder.Entity<NonCitizen>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("nonCitizen_pkey");

            entity.ToTable("nonCitizen");

            entity.HasIndex(e => e.Email, "nonCitizen_email_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.Email)
                .HasMaxLength(65)
                .HasColumnName("email");

            entity.HasOne(d => d.IdNavigation).WithOne(p => p.NonCitizen)
                .HasForeignKey<NonCitizen>(d => d.Id)
                .HasConstraintName("nonCitizen_id_fkey");
        });

        modelBuilder.Entity<Organization>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("organization_pkey");

            entity.ToTable("organization");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(65)
                .HasColumnName("name");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("user_pkey");

            entity.ToTable("user");

            entity.HasIndex(e => e.UserName, "user_userName_key").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.FirstName)
                .HasMaxLength(65)
                .HasColumnName("firstName");
            entity.Property(e => e.LastName)
                .HasMaxLength(65)
                .HasColumnName("lastName");
            entity.Property(e => e.Password)
                .HasMaxLength(65)
                .HasColumnName("password");
            entity.Property(e => e.UserName)
                .HasMaxLength(65)
                .HasColumnName("userName");
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => new { e.NonCitizenId, e.OrganizationId, e.Role }).HasName("userRole_pkey");

            entity.ToTable("userRole");

            entity.Property(e => e.NonCitizenId).HasColumnName("nonCitizenId");
            entity.Property(e => e.OrganizationId).HasColumnName("organizationId");
            entity.Property(e => e.Role)
                .HasMaxLength(65)
                .HasColumnName("role");

            entity.HasOne(d => d.NonCitizen).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.NonCitizenId)
                .HasConstraintName("userRole_nonCitizenId_fkey");

            entity.HasOne(d => d.Organization).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.OrganizationId)
                .HasConstraintName("userRole_organizationId_fkey");
        });
        modelBuilder.HasSequence<int>("class_id_seq");
        modelBuilder.HasSequence<int>("image_id_seq");
        modelBuilder.HasSequence<int>("organization_id_seq");
        modelBuilder.HasSequence<int>("user_id_seq");

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
